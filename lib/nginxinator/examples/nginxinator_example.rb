class NginxInstance

  ## For a standard Ubuntu 12.04 Nginx Docker image you should only
  ##  need to change the following values to get started:
    def domain
      "client.example.com"
    end

    def sites_enabled
      ['client-app']
    end

    def publish_ports
      [
        {
          "external" => "80",
          "internal" => "80"
        },
        {
          "external" => "443",
          "internal" => "443"
        }
      ]
    end

    def image_name
      "snarlysodboxer/nginx:0.0.0"
    end

    def external_data_path
      "/var/www/current"
    end

    def external_logs_path
      "/var/log/nginx"
    end



  ## The values below may be commonly changed to match specifics
  ##  relating to a particular Docker image or setup:
    def config_files
      ["nginx.conf", "ssl.crt", "ssl.key", "mime.types"]
    end

    def internal_data_path
      "/var/www/current"
    end

    def internal_conf_path
      "/etc/nginx"
    end

    def internal_sites_enabled_path
      "/etc/nginx/sites-enabled"
    end

    def internal_logs_path
      "/var/log/nginx"
    end

    def internal_sock_path
      "/var/run/unicorn"
    end

    def ssh_user
      ENV["USER"]
    end



  ## The values below are not meant to be changed and shouldn't
  ##  need to be under the majority of circumstances:

  def external_conf_path
    "/#{container_name}-conf"
  end

  def external_sites_enabled_path
    "#{external_conf_path}/sites-enabled"
  end

  def external_sock_path
    "#{external_conf_path}/run"
  end

  def container_name
    "#{domain}-nginx-#{publish_ports.collect { |p| p['external'] }.join('-')}"
  end

  def docker_run_command
    ports_options = []
    publish_ports.each do |port_set|
      ports_options += ["--publish", "0.0.0.0:#{port_set['external']}:#{port_set['internal']}"]
    end
    [ "--detach", "--tty",
      "--name",   container_name,
      "--volume", "#{external_data_path}:#{internal_data_path}:rw",
      "--volume", "#{external_conf_path}:#{internal_conf_path}:rw",
      "--volume", "#{external_sock_path}:#{internal_sock_path}:rw",
      "--volume", "#{external_logs_path}:#{internal_logs_path}:rw",
      ports_options,
      image_name
    ].flatten
  end

  def local_templates_path
    "templates/nginx"
  end

  def local_site_templates_path
    "#{local_templates_path}/sites-enabled"
  end

end
