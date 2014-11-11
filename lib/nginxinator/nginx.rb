require 'erb'

## NOTES:
# tasks without 'desc' description lines are for manual debugging of this
#   deployment code.
#
# we've choosen to only pass strings (if anything) to tasks. this allows tasks to be
#   debugged individually. only private methods take ruby objects.

namespace :nginx do

  desc "Idempotently setup an Nginx instance using values in ./config/deploy/<stage>_nginxinator.rb"
  task :setup do
    Rake::Task['nginx:ensure_access_docker'].invoke
    Rake::Task['nginx:open_firewall'].invoke
    # 'on', 'run_locally', 'as', 'execute', 'info', 'warn', and 'fatal' are from SSHKit
    on roles(:app) do
      config_file_changed = false
      fetch(:config_files).each do |config_file|
        if nginx_config_file_differs?(fetch(:local_templates_path), fetch(:external_conf_path), config_file)
          warn "Config file #{config_file} on #{fetch(:domain)} is being updated."
          Rake::Task['nginx:install_config_file'].invoke(fetch(:local_templates_path), fetch(:external_conf_path), config_file)
          Rake::Task['nginx:install_config_file'].reenable
          config_file_changed = true
        end
      end
      fetch(:sites_enabled).each do |config_file|
        if nginx_config_file_differs?(fetch(:local_site_templates_path), fetch(:external_sites_enabled_path), config_file)
          warn "Config file #{config_file} on #{fetch(:domain)} is being updated."
          Rake::Task['nginx:install_config_file'].invoke(fetch(:local_site_templates_path), fetch(:external_sites_enabled_path), config_file)
          Rake::Task['nginx:install_config_file'].reenable
          config_file_changed = true
        end
      end
      execute "sudo", "mkdir", "-p", fetch(:external_sock_path)
      execute "sudo", "chown", "-R", "www-data:www-data", fetch(:external_sock_path)
      unless nginx_container_exists?
        Rake::Task['nginx:create_container'].invoke
      else
        unless nginx_container_is_running?
          Rake::Task['nginx:start_container'].invoke
        else
          if config_file_changed
            Rake::Task['nginx:restart_container'].invoke
          else
            info "No config file changes for #{fetch(:nginx_container_name)} and it is already running; we're setup!"
          end
        end
      end
    end
  end

  desc "Check the status of the Nginx instance."
  task :status do
    on roles(:app) do
      info ""
      if nginx_container_exists?
        info "#{fetch(:nginx_container_name)} exists on #{fetch(:domain)}"
        info ""
        if nginx_container_is_running?
          info "#{fetch(:nginx_container_name)} is running on #{fetch(:domain)}"
          info ""
        else
          info "#{fetch(:nginx_container_name)} is not running on #{fetch(:domain)}"
          info ""
        end
      else
        info "#{fetch(:nginx_container_name)} does not exist on #{fetch(:domain)}"
        info ""
      end
    end
  end

  task :create_container do
    on roles(:app) do
      warn "Starting a new container named #{fetch(:nginx_container_name)} on #{fetch(:domain)}"
      execute("docker", "run", fetch(:docker_run_command))
      sleep 2
      fatal nginx_stay_running_message and raise unless nginx_container_is_running?
    end
  end

  task :start_container do
    on roles(:app) do
      warn "Starting an existing but non-running container named #{fetch(:nginx_container_name)}"
      execute("docker", "start", fetch(:nginx_container_name))
      sleep 2
      fatal nginx_stay_running_message and raise unless nginx_container_is_running?
    end
  end

  task :restart_container do
    on roles(:app) do
      warn "Restarting a running container named #{fetch(:nginx_container_name)}"
      execute("docker", "restart", fetch(:nginx_container_name))
      sleep 2
      fatal nginx_stay_running_message and raise unless nginx_container_is_running?
    end
  end

  task :ensure_access_docker do
    on roles(:app) do
      as fetch(:ssh_user) do
        unless test("bash", "-c", "\"docker", "ps", "&>", "/dev/null\"")
          execute("sudo", "usermod", "-a", "-G", "docker", fetch(:ssh_user))
          fatal "Newly added to docker group, this run will fail, next run will succeed. Simply try again."
        end
      end
    end
  end

  task :install_config_file, [:template_path, :config_path, :config_file] do |t, args|
    on roles(:app) do
      as 'root' do
        execute("mkdir", "-p", args.config_path) unless test("test", "-d", args.config_path)
        generated_config_file = nginx_generate_config_file("#{args.template_path}/#{args.config_file}.erb")
        upload! StringIO.new(generated_config_file), "/tmp/#{args.config_file}"
        execute("mv", "/tmp/#{args.config_file}", "#{args.config_path}/#{args.config_file}")
        execute("chown", "-R", "root:root", args.config_path)
        execute("chmod", "-R", "700", args.config_path)
      end
    end
  end

  task :open_firewall do
    on roles(:app) do
      as "root" do
        if test "ufw", "status"
          fetch(:publish_ports).collect { |port_set| port_set['external'] }.each do |port|
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
    def nginx_stay_running_message
      "Container #{fetch(:nginx_container_name)} on #{fetch(:domain)} did not stay running more than 2 seconds"
    end

    def nginx_config_file_differs?(local_templates_path, external_config_path, config_file)
      generated_config_file = nginx_generate_config_file("#{local_templates_path}/#{config_file}.erb")
      as 'root' do
        config_file_path = "#{external_config_path}/#{config_file}"
        if nginx_file_exists?(config_file_path)
          capture("cat", config_file_path).chomp != generated_config_file.chomp
        else
          true
        end
      end
    end

    def nginx_generate_config_file(template_file_path)
      set :logs_path,               -> { fetch(:internal_logs_path) }
      set :conf_path,               -> { fetch(:internal_conf_path) }
      set :sock_path,               -> { fetch(:internal_sock_path) }
      set :data_path,               -> { fetch(:internal_data_path) }
      set :sites_path,              -> { fetch(:internal_sites_enabled_path) }
      set :cdomain,                 -> { fetch(:domain) }
      @internal_logs_path           = fetch(:logs_path)
      @internal_conf_path           = fetch(:conf_path)
      @internal_sock_path           = fetch(:sock_path)
      @internal_data_path           = fetch(:data_path)
      @internal_sites_enabled_path  = fetch(:sites_path)
      @domain                       = fetch(:cdomain)
      template_path = File.expand_path(template_file_path)
      ERB.new(File.new(template_path).read).result(binding)
    end

    def nginx_container_exists?
      test "docker", "inspect", fetch(:nginx_container_name), ">", "/dev/null"
    end

    def nginx_container_is_running?
      (capture "docker", "inspect",
        "--format='{{.State.Running}}'",
        fetch(:nginx_container_name)).strip == "true"
    end

    def nginx_file_exists?(file_name_path)
      test "[", "-f", file_name_path, "]"
    end

end
