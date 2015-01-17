##### nginxinator
### ------------------------------------------------------------------
set :domain,                        "my-app.example.com"
server fetch(:domain),
  :user                             => fetch(:deployment_username),
  :roles                            => ["app", "web", "db"]
set :webserver_publish_ports,       ["80", "443"]
set :webserver_image_name,          "snarlysodboxer/nginx:0.0.0"
### ------------------------------------------------------------------
