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
      container_id = start_image_container(env.image, volumes: env.volumes)

      if env.stage&.commands
        run_and_cache_commands(
          env.stage.commands,
          cacheable_envs: config.cachable_envs?,
          container_id: container_id
        )
      end

      container_id
    end

    def container_id_for_cached_image(env)
      commands = env.stage.commands
      last_cached_stage_command = commands.reverse.find(&:cache)
      return unless last_cached_stage_command

      container_id = start_image_container(last_cached_stage_command.cache, volumes: env.volumes)
      uncached_commands = commands[commands.index(last_cached_stage_command) + 1..-1]
      run_and_cache_commands(uncached_commands, container_id: container_id)
      container_id
    end

    def run_and_cache_commands(commands, cacheable_envs: true, container_id:)
      commands.each do |command|
        run_container_command(container_id, command.value, success_only: false)
        cache_container(container_id, tag: command.hash) if cacheable_envs
      end
    end

    def pull(image)
      run_command("docker pull #{image}", no_capture: true)
    end

    def pull_if_missing(image)
      pull(image) unless presence(image)
    end

    def presence(image)
      image unless run_command("docker images -q #{image}").empty?
    end

    def cache_presence(hash)
      presence("#{CACHED_IMAGES_NAME}:#{hash}")
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
