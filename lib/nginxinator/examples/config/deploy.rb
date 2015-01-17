# config valid only for Capistrano 3.2.1
lock '3.2.1'

##### nginxinator
### ------------------------------------------------------------------
set :application,                   "my_app_name"
set :preexisting_ssh_user,          ENV['USER']
set :deployment_username,           "deployer"
set :webserver_username,            "www-data"
set :webserver_owned_dirs,          [shared_path.join('tmp', 'cache'), shared_path.join('public', 'assets')]
set :webserver_writeable_dirs,      [shared_path.join('run'), shared_path.join('tmp'), shared_path.join('log')]
set :webserver_executable_dirs,     [shared_path.join('bundle', 'bin')]
set :ignore_permissions_dirs,       [shared_path.join('postgres'), shared_path.join('nginx')]
### ------------------------------------------------------------------
