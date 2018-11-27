# frozen_string_literal: true

module Performa
  module Stages
    module_function

    extend ShellHelper

    def process(env, container_id:, config:)
      return unless env.stage

      env.stage[1].each do |command|
        result = run_container_command(container_id, command, success_only: false)
        raise(CommandFailureError, result) if result.failure?
      end

      Images.cache_container(container_id, tag: env.hash) if config.cachable_envs?
    end
  end
end
