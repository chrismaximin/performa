# frozen_string_literal: true

require "digest/sha1"

module Performa
  class Stage
    def self.from_config(config_stage, image:)
      hash = Digest::SHA1.hexdigest(image)

      commands = config_stage[1].map do |config_command|
        hash = Digest::SHA1.hexdigest(hash + config_command)
        StageCommand.new(config_command, hash: hash)
      end

      new(name: config_stage[0], commands: commands)
    end

    attr_reader :name, :commands, :hash

    def initialize(name:, commands:)
      @name = name
      @commands = commands
      @hash = Digest::SHA1.hexdigest(@name + @commands.map(&:hash).join)
    end
  end

  class StageCommand
    attr_reader :value, :hash

    def initialize(value, hash:)
      @value = value
      @hash = hash
    end

    def cache
      @cache ||= Images.cache_presence(@hash)
    end
  end
end
