Gem::Specification.new do |s|
  s.name        = 'nginxinator'
  s.version     = '0.2.2'
  s.date        = '2015-01-30'
  s.summary     = "Deploy Nginx"
  s.description = "Deploy Nginx instances using Capistrano and Docker"
  s.authors     = ["david amick"]
  s.email       = "davidamick@ctisolutionsinc.com"
  s.files       = [
    "lib/nginxinator.rb",
    "lib/nginxinator/nginx.rb",
    "lib/nginxinator/config.rb",
    "lib/nginxinator/check.rb",
    "lib/nginxinator/built-in.rb",
    "lib/nginxinator/examples/Capfile",
    "lib/nginxinator/examples/config/deploy.rb",
    "lib/nginxinator/examples/config/deploy/staging.rb",
    "lib/nginxinator/examples/nginx.conf.erb",
    "lib/nginxinator/examples/ssl.crt.erb",
    "lib/nginxinator/examples/ssl.key.erb",
    "lib/nginxinator/examples/mime.types.erb",
    "lib/nginxinator/examples/Dockerfile"
  ]
  s.required_ruby_version  =                '>= 1.9.3'
  s.requirements           <<               "Docker ~> 1.3.1"
  s.add_runtime_dependency 'capistrano',    '~> 3.2.1'
  s.add_runtime_dependency 'deployinator',  '~> 0.1.3'
  s.add_runtime_dependency 'rake',          '~> 10.3.2'
  s.add_runtime_dependency 'sshkit',        '~> 1.5.1'
  s.homepage    =
    'https://github.com/snarlysodboxer/nginxinator'
  s.license     = 'GNU'
end
