namespace :nginx do
  namespace :check do

    desc 'Ensure all nginxinator specific settings are set, and warn and exit if not.'
    before 'nginx:setup', :settings => 'deployinator:load_settings' do
      {
        (File.dirname(__FILE__) + "/examples/config/deploy.rb") => 'config/deploy.rb',
        (File.dirname(__FILE__) + "/examples/config/deploy/staging.rb") => "config/deploy/#{fetch(:stage)}.rb"
      }.each do |abs, rel|
        Rake::Task['deployinator:settings'].invoke(abs, rel)
        Rake::Task['deployinator:settings'].reenable
      end
    end

    namespace :settings do
      desc 'Print example nginxinator specific settings for comparison.'
      task :print => 'deployinator:load_settings' do
        set :print_all, true
        Rake::Task['nginx:check:settings'].invoke
      end
    end

  end
end
