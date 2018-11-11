# frozen_string_literal: true

require "yaml"
require "pty"
require "maestry/version"
require "maestry/config"

module Maestry
  Error = Class.new(StandardError)

  class << self
    def run_command(command, success_only: true, silent: false)
      unless silent
        puts "#{"=" * 40}\nRunning `#{command}` ..."
      end

      result = ""
      PTY.spawn(command) do |stdout, stdin, pid|
        begin
          stdout.each do |line|
            print(line) unless silent
            result += line
          end
        rescue Errno::EIO
          puts "--- Errno::EIO ---"
        end
      end

      raise Error.new("An error occurred.") if !$?.success? && success_only
      result
    end
  end

  class Coordinator
    def initialize(config_file: nil)
      @config = Config.new(config_file)
    end

    def run
      pull_images

    end

    def pull_images
      @config.images.each do |image|
        Maestry::run_command("docker pull #{image}")
      end
    end

    def missing_images
      @config.images.filter do |image|
        # TODO
      end
    end
  end

  # class Runner
  # end
end
