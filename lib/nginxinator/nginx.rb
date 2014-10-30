require 'erb'

require './nginxinator.rb' if File.exists?('./nginxinator.rb')

## NOTES:
# tasks without 'desc' description lines are for manual debugging of this
#   deployment code.
#
# we've choosen to only pass strings (if anything) to tasks. this allows tasks to be
#   debugged individually. only private methods take ruby objects.

namespace :nginx do

  desc "Idempotently setup one or more Nginx instances using values in ./nginxinator.rb"
  task :setup => :ensure_setup do
    # instance variables are lost inside SSHKit's 'on' block, so
    #   at the beginning of each task we assign 'settings' to @settings.
    settings = @settings
    Rake::Task['nginx:ensure_access_docker'].invoke
    Rake::Task['nginx:open_firewall'].invoke
    # 'on', 'run_locally', 'as', 'execute', 'info', 'warn', and 'fatal' are from SSHKit
    on "#{settings.ssh_user}@#{settings.domain}" do
      config_file_changed = false
      settings.config_files.each do |config_file|
        if nginx_config_file_differs?(settings, settings.local_templates_path, settings.external_conf_path, config_file)
          warn "Config file #{config_file} on #{settings.domain} is being updated."
          Rake::Task['nginx:install_config_file'].invoke(settings.local_templates_path, settings.external_conf_path, config_file)
          Rake::Task['nginx:install_config_file'].reenable
          config_file_changed = true
        end
      end
      settings.sites_enabled.each do |config_file|
        if nginx_config_file_differs?(settings, settings.local_site_templates_path, settings.external_sites_enabled_path, config_file)
          warn "Config file #{config_file} on #{settings.domain} is being updated."
          Rake::Task['nginx:install_config_file'].invoke(settings.local_site_templates_path, settings.external_sites_enabled_path, config_file)
          Rake::Task['nginx:install_config_file'].reenable
          config_file_changed = true
        end
      end
      unless nginx_container_exists?(settings.container_name)
        Rake::Task['nginx:create_container'].invoke
      else
        unless nginx_container_is_running?(settings.container_name)
          Rake::Task['nginx:start_container'].invoke
        else
          if config_file_changed
            Rake::Task['nginx:restart_container'].invoke
          else
            info "No config file changes for #{settings.container_name} and it is already running; we're setup!"
          end
        end
      end
    end
  end

  desc "Check the status of the Nginx instance."
  task :status => :ensure_setup do |t, args|
    settings = @settings
    on "#{settings.ssh_user}@#{settings.domain}" do
      info ""
      if nginx_container_exists?(settings.container_name)
        info "#{settings.container_name} exists on #{settings.domain}"
        info ""
        if nginx_container_is_running?(settings.container_name)
          info "#{settings.container_name} is running on #{settings.domain}"
          info ""
        else
          info "#{settings.container_name} is not running on #{settings.domain}"
          info ""
        end
      else
        info "#{settings.container_name} does not exist on #{settings.domain}"
        info ""
      end
    end
  end

  task :create_container => :ensure_setup do |t, args|
    settings = @settings
    on "#{settings.ssh_user}@#{settings.domain}" do
      warn "Starting a new container named #{settings.container_name} on #{settings.domain}"
      execute("docker", "run", settings.docker_run_command)
      sleep 2
      fatal nginx_stay_running_message(settings) and raise unless nginx_container_is_running?(settings.container_name)
    end
  end

  task :start_container => :ensure_setup do |t, args|
    settings = @settings
    on "#{settings.ssh_user}@#{settings.domain}" do
      warn "Starting an existing but non-running container named #{settings.container_name}"
      execute("docker", "start", settings.container_name)
      sleep 2
      fatal nginx_stay_running_message(settings) and raise unless nginx_container_is_running?(settings.container_name)
    end
  end

  task :restart_container => :ensure_setup do |t, args|
    settings = @settings
    on "#{settings.ssh_user}@#{settings.domain}" do
      warn "Restarting a running container named #{settings.container_name}"
      execute("docker", "restart", settings.container_name)
      sleep 2
      fatal nginx_stay_running_message(settings) and raise unless nginx_container_is_running?(settings.container_name)
    end
  end

  task :ensure_access_docker => :ensure_setup do |t, args|
    settings = @settings
    on "#{settings.ssh_user}@#{settings.domain}" do
      as settings.ssh_user do
        unless test("bash", "-c", "\"docker", "ps", "&>", "/dev/null\"")
          execute("sudo", "usermod", "-a", "-G", "docker", settings.ssh_user)
          fatal "Newly added to docker group, this run will fail, next run will succeed. Simply try again."
        end
      end
    end
  end

  task :install_config_file, [:template_path, :config_path, :config_file] => :ensure_setup do |t, args|
    settings = @settings
    on "#{settings.ssh_user}@#{settings.domain}" do
      as 'root' do
        execute("mkdir", "-p", args.config_path) unless test("test", "-d", args.config_path)
        generated_config_file = nginx_generate_config_file(settings, "#{args.template_path}/#{args.config_file}.erb")
        upload! StringIO.new(generated_config_file), "/tmp/#{args.config_file}"
        execute("mv", "/tmp/#{args.config_file}", "#{args.config_path}/#{args.config_file}")
        execute("chown", "-R", "root:root", args.config_path)
        execute("chmod", "-R", "700", args.config_path)
      end
    end
  end

  task :open_firewall => :ensure_setup do |t, args|
    settings = @settings
    on "#{settings.ssh_user}@#{settings.domain}" do
      as "root" do
        if test "ufw", "status"
          settings.publish_ports.collect { |port_set| port_set['external'] }.each do |port|
            raise "Error during opening UFW firewall" unless test("ufw", "allow", "#{port}/tcp")
          end
        end
      end
    end
  end

  private

    # Temporarily added 'nginx_' to the beginning of each of these methods to avoid
    #   getting them overwritten by other gems with methods with the same names, (E.G. postgresinator.)
    ## TODO Figure out how to do this the right or better way.
    def nginx_stay_running_message(settings)
      "Container #{settings.container_name} on #{settings.domain} did not stay running more than 2 seconds"
    end

    def nginx_config_file_differs?(settings, local_templates_path, external_config_path, config_file)
      generated_config_file = nginx_generate_config_file(settings, "#{local_templates_path}/#{config_file}.erb")
      as 'root' do
        config_file_path = "#{external_config_path}/#{config_file}"
        if nginx_file_exists?(config_file_path)
          capture("cat", config_file_path).chomp != generated_config_file.chomp
        else
          true
        end
      end
    end

    def nginx_generate_config_file(settings, template_file_path)
      @settings     = settings # needed for ERB
      template_path = File.expand_path(template_file_path)
      ERB.new(File.new(template_path).read).result(binding)
    end

    def nginx_container_exists?(container_name)
      test "docker", "inspect", container_name, ">", "/dev/null"
    end

    def nginx_container_is_running?(container_name)
      (capture "docker", "inspect",
        "--format='{{.State.Running}}'",
        container_name).strip == "true"
    end

    def nginx_file_exists?(file_name_path)
      test "[", "-f", file_name_path, "]"
    end

end
