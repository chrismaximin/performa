# frozen_string_literal: true

module Performa
  module Images
    module_function

    extend ShellHelper
    CACHED_IMAGES_NAME = "performa_env"

    def process(env, config:)
      if config.cachable_envs?
        container_id = container_id_for_cached_image(env)
        return container_id if container_id
      end

      pull_if_missing(env.image)
      id = start_image_container(env.image, volumes: env.volumes)
      ContainerId.new(id)
    end

    def container_id_for_cached_image(env)
      cached_image = "#{CACHED_IMAGES_NAME}:#{env.hash}"
      return unless exists?(cached_image)

      id = start_image_container(cached_image, volumes: env.volumes)
      ContainerId.from_cache(id)
    end

    def pull(image)
      run_command("docker pull #{image}", no_capture: true)
    end

    def pull_if_missing(image)
      pull(image) unless exists?(image)
    end

    def exists?(image)
      !run_command("docker images -q #{image}").empty?
    end

    def start_image_container(image, volumes: [])
      volumes_options = volumes.map do |volume|
        volume[0] = Dir.pwd if volume[0] == "."
        " -v #{volume}"
      end.join

      command = "docker run #{volumes_options} -d #{image} tail -f /dev/null"

      run_command(command).strip.tap do |container_id|
        ContainerRegistry.add(container_id)
      end
    end

    def cache_container(container_id, tag:)
      run_command("docker commit #{container_id} #{CACHED_IMAGES_NAME}:#{tag}")
    end

    def clear_cached
      ids = run_command("docker images --filter=reference='#{CACHED_IMAGES_NAME}' --format '{{.ID}}'").split("\n")
      ids.each do |id|
        run_command("docker rmi -f #{id.strip}")
      end
    end
  end
end
