namespace :nginx do

  task :ensure_setup do |t, args|
    @settings = NginxInstance.new
    # use 'rake nginx:COMMAND debug=true' for debugging (you can also add --trace if you like)
    SSHKit.config.output_verbosity = Logger::DEBUG if ENV['debug'] == "true"
  end

  desc 'Write example config files'
  task :write_example_configs do
    run_locally do
      execute "mkdir -p templates/nginx/sites-enabled"
      {
        'examples/Dockerfile'               => 'Dockerfile_example',
        'examples/nginxinator_example.rb'   => 'nginxinator_example.rb',
        'examples/nginx_example.conf.erb'   => 'templates/nginx/nginx_example.conf.erb',
        'examples/site-enabled_example.erb' => 'templates/nginx/sites-enabled/client-app_example.erb',
        'examples/ssl.crt_example.erb'      => 'templates/nginx/ssl.crt_example.erb',
        'examples/ssl.key_example.erb'      => 'templates/nginx/ssl.key_example.erb',
        'examples/mime.types_example.erb'   => 'templates/nginx/mime.types_example.erb'
      }.each do |source, destination|
        config = File.read(File.dirname(__FILE__) + "/#{source}")
        File.open("./#{destination}", 'w') { |f| f.write(config) }
        info "Wrote '#{destination}'"
      end
      info "Now remove the '_example' portion of their names or diff with existing files and add the needed lines."
    end
  end

end
