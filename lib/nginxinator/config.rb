namespace :nginxinator do

  desc 'Write example config files'
  task :write_example_configs do
    run_locally do
      execute "mkdir", "-p", "config/deploy", "templates/nginx"
      {
        'examples/Capfile'                              => 'Capfile_example',
        'examples/config/deploy.rb'                     => 'config/deploy_example.rb',
        'examples/config/deploy/staging.rb'             => 'config/deploy/staging_example.rb',
        'examples/Dockerfile'                           => 'templates/nginx/Dockerfile_example',
        'examples/nginx.conf.erb'                       => 'templates/nginx/nginx_example.conf.erb',
        'examples/ssl.crt.erb'                          => 'templates/nginx/ssl.crt_example.erb',
        'examples/ssl.key.erb'                          => 'templates/nginx/ssl.key_example.erb',
        'examples/mime.types.erb'                       => 'templates/nginx/mime.types_example.erb'
      }.each do |source, destination|
        config = File.read(File.dirname(__FILE__) + "/#{source}")
        File.open("./#{destination}", 'w') { |f| f.write(config) }
        info "Wrote '#{destination}'"
      end
      info "Now remove the '_example' portion of their names or diff with existing files and add the needed lines."
    end
  end

end
