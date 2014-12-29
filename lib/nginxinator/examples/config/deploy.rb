# config valid only for Capistrano 3.1
lock '3.2.1'

set :preexisting_ssh_user,          ENV['USER']
set :deployment_username,           "deployer"
set :webserver_username,            "www-data"
set :webserver_config_files,        ["nginx.conf", "ssl.crt", "ssl.key", "mime.types"]
set :webserver_data_path,           current_path
set :webserver_logs_path,           shared_path.join('log')
set :webserver_config_path,         shared_path.join('nginx')
set :webserver_socket_path,         shared_path.join('run')
set :webserver_writeable_dirs,      [shared_path.join('run'), shared_path.join('log')]
set :webserver_executable_dirs,     [shared_path.join('bundle', 'bin')]
set :ignore_permissions_dirs,       [shared_path.join('postgres'), shared_path.join('nginx')]
set :webserver_container_name,      -> { "#{fetch(:domain)}-nginx-#{fetch(:webserver_publish_ports).join('-')}" }
set :webserver_ports_options,       -> { fetch(:webserver_publish_ports).collect { |p| ["--publish", "0.0.0.0:#{p}:#{p}"] }.flatten }
set :webserver_docker_run_command,  -> { [
  "--detach", "--tty",
  "--name",   fetch(:webserver_container_name),
  "--volume", "#{fetch(:deploy_to)}:#{fetch(:deploy_to)}:rw",
  "--entrypoint", "/usr/sbin/nginx",
  "--restart", "always",
  fetch(:webserver_ports_options),
  fetch(:webserver_image_name),
  "-c", shared_path.join('nginx', 'nginx.conf')
].flatten }
set :local_templates_path,          "templates/nginx"
