namespace :nginx do

  task :ensure_setup => ['nginxinator:deployment_user', 'nginxinator:webserver_user', 'deployinator:sshkit_umask'] do
    SSHKit.config.output_verbosity = fetch(:webserver_log_level)
  end

  desc "Idempotently setup an Nginx instance."
  task :setup => [:ensure_setup] do
    Rake::Task['nginx:open_firewall'].invoke
    # 'on', 'run_locally', 'as', 'execute', 'info', 'warn', and 'fatal' are from SSHKit
    on roles(:app) do |host|
      as :root do
        set :config_file_changed, false
        Rake::Task['nginx:install_config_files'].invoke
        Rake::Task['nginxinator:file_permissions'].invoke
        name = fetch(:webserver_container_name)
        unless container_exists?(name)
          warn "Starting a new container named #{name} on #{host}"
          webserver_run(host)
        else
          unless container_is_running?(name)
            start_container(name)
          else
            if fetch(:config_file_changed)
              restart_container(name)
            else
              info "No config file changes for #{name} and it is already running; we're setup!"
            end
          end
        end
      end
    end
  end

  desc "Check the status of the Nginx instance."
  task :status => [:ensure_setup] do
    on roles(:app) do
      info ""
      name = fetch(:webserver_container_name)
      if container_exists?(name)
        info "#{name} exists on #{fetch(:domain)}"
        info ""
        if container_is_running?(name)
          info "#{name} is running on #{fetch(:domain)}"
          info ""
        else
          info "#{name} is not running on #{fetch(:domain)}"
          info ""
        end
      else
        info "#{name} does not exist on #{fetch(:domain)}"
        info ""
      end
    end
  end

  task :install_config_files => [:ensure_setup] do
    require 'erb'
    on roles(:app) do
      as 'root' do
        execute "mkdir", "-p", fetch(:webserver_socket_path),
          fetch(:webserver_logs_path), fetch(:webserver_config_path)
        fetch(:webserver_config_files).each do |config_file|
          template_path = File.expand_path("#{fetch(:webserver_templates_path)}/#{config_file}.erb")
          generated_config_file = ERB.new(File.new(template_path).read).result(binding)
          upload! StringIO.new(generated_config_file), "/tmp/#{config_file}.file"
          unless test "diff", "-q", "/tmp/#{config_file}.file", "#{fetch(:webserver_config_path)}/#{config_file}"
            warn "Config file #{config_file} on #{fetch(:domain)} is being updated."
            execute("mv", "/tmp/#{config_file}.file", "#{fetch(:webserver_config_path)}/#{config_file}")
            set :config_file_changed, true
          else
            execute "rm", "/tmp/#{config_file}.file"
          end
        end
        execute("chown", "-R", "root:root", fetch(:webserver_config_path))
        execute "find", fetch(:webserver_config_path), "-type", "d", "-exec", "chmod", "2775", "{}", "+"
        execute "find", fetch(:webserver_config_path), "-type", "f", "-exec", "chmod", "0600", "{}", "+"
      end
    end
  end

  task :open_firewall => [:ensure_setup] do
    on roles(:app) do
      as "root" do
        if test "bash", "-c", "\"ufw", "status", "&>" "/dev/null\""
          fetch(:webserver_publish_ports).each do |port|
            raise "Error during opening UFW firewall" unless test("ufw", "allow", "#{port}/tcp")
          end
        end
      end
    end
  end

end
