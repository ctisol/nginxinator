module Nginxinator
  def stay_running_message(settings)
    "Container #{settings.container_name} on #{settings.domain} did not stay running more than 2 seconds"
  end

  def config_file_differs?(settings, local_templates_path, external_config_path, config_file)
    generated_config_file = generate_config_file(settings, "#{local_templates_path}/#{config_file}.erb")
    as 'root' do
      config_file_path = "#{external_config_path}/#{config_file}"
      if file_exists?(config_file_path)
        capture("cat", config_file_path).chomp != generated_config_file.chomp
      else
        true
      end
    end
  end

  def generate_config_file(settings, template_file_path)
    @settings     = settings # needed for ERB
    template_path = File.expand_path(template_file_path)
    ERB.new(File.new(template_path).read).result(binding)
  end

  def container_exists?(container_name)
    test "docker", "inspect", container_name, ">", "/dev/null"
  end

  def container_is_running?(container_name)
    (capture "docker", "inspect",
      "--format='{{.State.Running}}'",
      container_name).strip == "true"
  end

  def file_exists?(file_name_path)
    test "[", "-f", file_name_path, "]"
  end
end
