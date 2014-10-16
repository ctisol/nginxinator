nginxinator
============

*Opinionatedly Deploy Nginx instances.*

This library uses Rake and SSHKit, and relies on SSH access with passwordless sudo rights, as well as Docker installed on the hosts.

You need to manually verify you are not attempting to setup more than one instance on the same port for a paricular domain (host), although Docker will simply error and tell you the port is already assigned.

### Installation:
* `gem install nginxinator` (Or add it to your Gemfile and `bundle install`.)
* Create a Rakefile which requires nginxinator:
`echo "require 'nginxinator'" > Rakefile`
* Create example configs:
`rake nginx:write_example_configs`
* Turn them into real configs by removing the `_example` portions of their names, and adjusting their content to fit your needs. (Later when you upgrade to a newer version of nginxinator, you can `nginx:write_example_configs` again and diff your current configs against the new configs to see what you need to add.)
* You can add any custom Nginx setting you need by adjusting the content of the ERB templates. You won't need to change them to get started, except for adding a valid SSL cert/key set.
* You can later update a template (Nginx config) and run `rake nginx:setup` again to update the config file and restart the instance.

### Usage:
`rake -T` will help remind you of the available commands, see this for more details.
* After setting up your `nginxinator.rb` config file during installation, simply run: `rake nginx:setup`
* Run `rake nginx:setup` again to see it find everything is already setup, and do nothing.
* Run `rake nginx:status` to see the status of the instance.
* An example Dockerfile is provided

###### Debugging:
* Run any task with `rake <task> debug=true` to get highly verbose SSHKit debug output. E.G. `rake nginx:setup debug=true`
* You can also add the `--trace` option at the end to see when which task is invoked, and when which task is actually executed.
* If you want to put on your DevOps hat, you can run `rake -T -A` to see each individually available task, and run them one at a time to debug each one.
