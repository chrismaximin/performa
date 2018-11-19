# frozen_string_literal: true

module Performa
  module Stages
    module_function

    extend ShellHelper

    def process(env, container_id:)
      return unless env.stage

      env.stage[1].each do |command|
        run_command("docker container exec #{container_id} #{command}")
      end
    end
  end
end
