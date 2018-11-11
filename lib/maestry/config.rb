# frozen_string_literal: true

module Maestry
  class Config
    DEFAULT_FILES = %w[
      maestry.yml config/maestry.yml
      spec/maestry.yml test/maestry.yml
    ].freeze

    ERR_NO_FILE = "Could not find a default config file (#{DEFAULT_FILES.join(', ')})"

    attr_reader :images, :script
    
    def initialize(config_file)
      config_file ||= find_default_config_file
      raise(Error, ERR_NO_FILE) unless config_file

      @data = load_config_file(config_file)
      validate_data(@data)

      @images = @data["images"]
      @script = @data["script"]
    end

    def load_config_file(config_file)
      YAML.safe_load(File.read(config_file))
    rescue Errno::EACCES => error
      raise Error, "Could not read config file #{config_file} (#{error.message})"
    rescue Psych::SyntaxError => error
      raise Error, "Invalid YAML file #{config_file}: #{error.message}"
    end

    def find_default_config_file
      DEFAULT_FILES.find do |file|
        File.exist?(file)
      end
    end

    def validate_data(data)
      # noop
    end
  end
end
