set :webserver_log_level,           "info"
set :webserver_config_files,        ["nginx.conf", "ssl.crt", "ssl.key", "mime.types"]
set :webserver_data_path,           -> { current_path }
set :webserver_logs_path,           -> { shared_path.join('log') }
set :webserver_config_path,         -> { shared_path.join('nginx') }
set :webserver_socket_path,         -> { shared_path.join('run') }
set :webserver_templates_path,      "templates/nginx"
set :webserver_container_name,      -> { "#{fetch(:domain)}-nginx-#{fetch(:webserver_publish_ports).join('-')}" }
set :webserver_ports_options,       -> { fetch(:webserver_publish_ports).collect { |p| ["--publish", "0.0.0.0:#{p}:#{p}"] }.flatten }

def webserver_run(host)
  execute("docker", "run", "--detach", "--tty",
    "--name",   fetch(:webserver_container_name),
    "--volume", "#{fetch(:deploy_to)}:#{fetch(:deploy_to)}:rw",
    "--entrypoint", "/usr/sbin/nginx",
    "--restart", "always",
    fetch(:webserver_ports_options),
    fetch(:webserver_image_name),
    "-c", shared_path.join('nginx', 'nginx.conf'))
end
