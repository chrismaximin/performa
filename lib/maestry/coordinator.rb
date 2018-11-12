# frozen_string_literal: true

module Maestry
  class Coordinator
    include ShellHelper

    def initialize(config_file: nil)
      @config = Configuration.new(config_file)
    end

    def run
      pull_images(missing_images)

      @config["images"].each do |image|
        env = Environment.from_image(image)
        # byebug

        env.container_id = run_image(image)
        byebug
        if @config["facets"]
          @config["facets"].each_pair do |facet, commands|
            env.facet = facet
            run_facet(commands, container_id: env.container_id)
            ContainerRegistry.kill(env.container_id)
          end
        else
          # if no facets
        end
      end
    ensure
      ContainerRegistry.kill_all
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

    def run_image(image)
      volumes_options = @config["volumes"]&.map do |volume|
        " -v #{volume}"
      end.join

      command = "docker run #{volumes_options} -d #{image} tail -f /dev/null"

      run_command(command).strip.tap do |container_id|
        ContainerRegistry.add(container_id)
      end
    end

    def run_facet(facet_setup_commands, container_id:)
      facet_setup_commands.each do |command|
        run_command("docker container exec #{container_id} #{command}")
      end

      run_command("docker container exec #{container_id} #{@config["command"]}")
    end
  end
end
