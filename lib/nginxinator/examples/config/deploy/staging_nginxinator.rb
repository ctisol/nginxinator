## For a standard Ubuntu 12.04 Nginx Docker image you should only
##  need to change the following values to get started:
set :domain,                      "client.example.com"
set :sites_enabled,               ['client-app']
set :publish_ports,               [
  {
    "external" => "80",
    "internal" => "80"
  },
  {
    "external" => "443",
    "internal" => "443"
  }
]
set :image_name,                  "snarlysodboxer/nginx:0.0.0"
set :external_data_path,          "/var/www/client-app/current"
set :external_logs_path,          "/var/www/client-app/shared/log/nginx"



## The values below may be commonly changed to match specifics
##  relating to a particular Docker image or setup:
set :config_files,                ["nginx.conf", "ssl.crt", "ssl.key", "mime.types"]
set :internal_data_path,          -> { fetch(:external_data_path) }
set :internal_conf_path,          "/etc/nginx"
set :internal_sites_enabled_path, "/etc/nginx/sites-enabled"
set :internal_logs_path,          "/var/log/nginx"
set :internal_sock_path,          "/var/run/unicorn"
set :ssh_user,                    -> { ENV["USER"] }



## The values below are not meant to be changed and shouldn't
##  need to be under the majority of circumstances:
set :nginx_container_name,        -> { "#{fetch(:domain)}-nginx-#{fetch(:publish_ports).collect { |p| p['external'] }.join('-')}" }
set :external_conf_path,          -> { "/#{fetch(:nginx_container_name)}-conf" }
set :external_sites_enabled_path, -> { "#{fetch(:external_conf_path)}/sites-enabled" }
set :external_sock_path,          -> { "#{fetch(:external_conf_path)}/run" }
set :ports_options,               -> {
  options = []
  fetch(:publish_ports).each do |port_set|
    options += ["--publish", "0.0.0.0:#{port_set['external']}:#{port_set['internal']}"]
  end
  options
}
set :docker_run_command,          -> { [
  "--detach", "--tty",
  "--name",   fetch(:nginx_container_name),
  "--volume", "#{fetch(:external_data_path)}:#{fetch(:internal_data_path)}:rw",
  "--volume", "#{fetch(:external_conf_path)}:#{fetch(:internal_conf_path)}:rw",
  "--volume", "#{fetch(:external_sock_path)}:#{fetch(:internal_sock_path)}:rw",
  "--volume", "#{fetch(:external_logs_path)}:#{fetch(:internal_logs_path)}:rw",
  "--restart", "always",
  fetch(:ports_options),
  fetch(:image_name)
].flatten }
set :local_templates_path,        "templates/nginx"
set :local_site_templates_path,   -> { "#{fetch(:local_templates_path)}/sites-enabled" }
