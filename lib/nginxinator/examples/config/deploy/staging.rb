set :domain,                        "my-app.example.com"
set :user_host,                     "#{fetch(:deployment_username)}@#{fetch(:domain)}"

role :app,                          fetch(:user_host)
role :web,                          fetch(:user_host)
role :db,                           fetch(:user_host)


# nginxinator
#--------------------------------------------------------------------------
set :webserver_publish_ports,       ["80", "443"]
set :webserver_image_name,          "snarlysodboxer/nginx:0.0.0"
#--------------------------------------------------------------------------
