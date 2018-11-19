# frozen_string_literal: true

require "digest"

module Maestry
  class Environment
    def self.all(config)
      unless config["stages"]
        return config["images"].map do |image|
          new(image: image, volumes: config["volumes"])
        end
      end

      config["images"].product(config["stages"].to_a).map do |image, stage|
        new(image: image, stage: stage, volumes: config["volumes"])
      end
    end

    attr_reader :image, :stage, :volumes, :name, :hash

    def initialize(image:, stage: nil, volumes: nil)
      @image = image
      @stage = stage
      @volumes = volumes || []
      assign_name
      assign_hash
    end

    def assign_name
      @name = @image.tr(":", "_") + ("-#{@stage[0]}" if @stage).to_s
    end

    def assign_hash
      @hash = Digest::SHA1.hexdigest(@image + @stage.to_s)
    end
  end
end
