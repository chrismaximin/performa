# frozen_string_literal: true

module Maestry
  class Configuration
    DEFAULT_FILES = %w[
      maestry.yml config/maestry.yml
      spec/maestry.yml test/maestry.yml
    ].freeze

    ERR_READING_CONFIG_FILE = "Could not read config file %s (%s)"
    ERR_INVALID_FILE = "Invalid YAML file %s: %s"
    ERR_NO_FILE = "Could not find a default config file (#{DEFAULT_FILES.join(', ')})"

    attr_reader :data

    def initialize(config_file)
      config_file ||= find_default_config_file
      raise(Error, ERR_NO_FILE) unless config_file

      @data = load_config_file(config_file)
      validate_data
    end

    def load_config_file(config_file)
      YAML.safe_load(File.read(config_file))
    rescue Errno::EACCES => error
      raise Error, format(ERR_READING_CONFIG_FILE, config_file, error.message)
    rescue Psych::SyntaxError => error
      raise Error, format(ERR_INVALID_FILE, config_file, error.message)
    end

    def find_default_config_file
      DEFAULT_FILES.find do |file|
        File.exist?(file)
      end
    end

    def validate_data
      # noop
    end

    def [](name)
      @data[name]
    end
  end
end
