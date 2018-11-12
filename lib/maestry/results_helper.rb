# frozen_string_literal: true

require "fileutils"
require "colorize"

module Maestry
  module ResultsHelper
    module_function

    def process(results, config:)
      if config["output"].nil? || config["output"] == "STDOUT"
        output_to_stdout(results)
      else
        output_to_directory(results, directory: config["output"])
      end
    end

    def output_to_stdout(results)
      results.each_pair do |env_name, result|
        puts
        puts "== Output for #{env_name}".colorize(:green)
        puts
        puts result
      end
      puts
    end

    def output_to_directory(results, directory:)
      FileUtils.mkdir_p(directory)
      filenames = []
      results.each_pair do |env_name, result|
        filename = File.join(directory, env_name + ".txt")
        filenames << filename

        File.open(filename, "w+") do |file|
          file.write(result)
        end
      end

      message = +"Command outputs are now present in the following files:\n"
      message << filenames.join("\n")

      puts
      puts message.colorize(:green)
      puts
    end
  end
end
