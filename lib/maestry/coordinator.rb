# frozen_string_literal: true

module Maestry
  class Coordinator
    include ShellHelper

    def initialize(config:)
      @config = config
    end

    def run
      pull_images(missing_images)
      results = {}

      @config["images"].each do |image|
        process_image(image, results: results)
      end

      ResultsHelper.process(results, config: @config)
    ensure
      ContainerRegistry.kill_all
    end

    def process_image(image, results:)
      env = Environment.from_image(image)
      container_id = start_image_container(image)

      default_facet = { "" => [] }
      (@config["facets"] || default_facet).each_pair do |facet_name, commands|
        env.facet = facet_name
        results[env.name] = process_facet(commands, container_id: container_id)
      end

      ContainerRegistry.kill(container_id)
    end

    def process_facet(commands, container_id:)
      (commands || []).each do |command|
        execute_command_on_container(command, container_id: container_id)
      end

      execute_command_on_container(@config["command"], container_id: container_id)
    end

    def pull_images(images)
      images.each do |image|
        run_command("docker pull #{image}")
      end
    end

    def missing_images
      @config["images"].select do |image|
        run_command("docker images -q #{image}").empty?
      end
    end

    def start_image_container(image)
      volumes_options = @config["volumes"]&.map do |volume|
        volume[0] = Dir.pwd if volume[0] == "."
        " -v #{volume}"
      end&.join

      command = "docker run #{volumes_options} -d #{image} tail -f /dev/null"

      run_command(command).strip.tap do |container_id|
        ContainerRegistry.add(container_id)
      end
    end

    def execute_command_on_container(command, container_id:)
      run_command("docker container exec #{container_id} #{command}")
    end
  end
end
