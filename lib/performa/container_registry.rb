# frozen_string_literal: true

require "set"

module Performa
  module ContainerRegistry
    module_function

    extend ShellHelper

    def add(container_id)
      containers << container_id
    end

    def kill_all
      containers.each do |container_id|
        kill(container_id)
      end
    end

    def kill(container_id)
      run_command("docker kill #{container_id}", success_only: false)
      containers.delete(container_id)
    end

    def containers
      Thread.current[:performa_containers] ||= Set.new
    end
  end
end
