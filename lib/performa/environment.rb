# frozen_string_literal: true

require "digest"

module Performa
  class Environment
    def self.all(config)
      config["stages"] ? all_with_active_stages(config) : all_without_stages(config)
    end

    def self.all_without_stages(config)
      config["images"].map do |image|
        new(image: image, volumes: config["volumes"])
      end
    end

    def self.all_with_active_stages(config)
      skipped = config["skip"]&.flat_map { |image, stages_names| [image].product(stages_names) }

      config["images"].product(config["stages"].to_a).map do |image, config_stage|
        next if skipped&.include?([image, config_stage[0]])

        stage = Stage.from_config(config_stage, image: image)
        new(image: image, stage: stage, volumes: config["volumes"])
      end.compact
    end

    attr_reader :image, :stage, :volumes, :name, :hash

    def initialize(image:, stage: nil, volumes: nil)
      @image = image
      @stage = stage
      @volumes = volumes || []
      assign_name
    end

    def assign_name
      @name = @image.tr(":", "_") + ("-#{@stage.name}" if @stage).to_s
    end
  end
end
