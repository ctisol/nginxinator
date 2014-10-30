Gem::Specification.new do |s|
  s.name        = 'nginxinator'
  s.version     = '0.0.2'
  s.date        = '2014-10-30'
  s.summary     = "Deploy Nginx"
  s.description = "An Opinionated Nginx Deployment gem"
  s.authors     = ["david amick"]
  s.email       = "davidamick@ctisolutionsinc.com"
  s.files       = [
    "lib/nginxinator.rb",
    "lib/nginxinator/nginx.rb",
    "lib/nginxinator/config.rb",
    "lib/nginxinator/examples/nginxinator_example.rb",
    "lib/nginxinator/examples/nginx_example.conf.erb",
    "lib/nginxinator/examples/site-enabled_example.erb",
    "lib/nginxinator/examples/ssl.crt_example.erb",
    "lib/nginxinator/examples/ssl.key_example.erb",
    "lib/nginxinator/examples/mime.types_example.erb",
    "lib/nginxinator/examples/Dockerfile"
  ]
  s.required_ruby_version  =              '>= 1.9.3'
  s.add_runtime_dependency 'rake',        '= 10.3.2'
  s.add_runtime_dependency 'sshkit',      '= 1.5.1'
  s.homepage    =
    'https://github.com/snarlysodboxer/nginxinator'
  s.license     = 'GNU'
end
