# frozen_string_literal: true

module Performa
  module Coordinator
    module_function

    extend ShellHelper

    def run(config)
      envs = Environment.all(config)
      results = {}

      envs.each do |env|
        results[env.name] = process_env(env, config: config)
      end

      ResultsHelper.process(results, config: config)
    ensure
      ContainerRegistry.kill_all
    end

    def process_env(env, config:)
      LOG.info_notice("Processing #{[env.image, env&.stage&.first].compact}")
      container_id = Images.process(env, config: config)
      Stages.process(env, container_id: container_id, config: config) unless container_id.from_cache
      run_container_command(container_id, config["command"], success_only: false)
    rescue CommandFailureError => error
      error.message
    ensure
      ContainerRegistry.kill(container_id)
    end
  end
end
