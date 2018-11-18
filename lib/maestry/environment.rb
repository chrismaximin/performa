# frozen_string_literal: true

require "digest"

module Maestry
  class Environment
    def self.all(config)
      unless config["facets"]
        return config["images"].map do |image|
          new(image: image, volumes: config["volumes"])
        end
      end

      config["images"].product(config["facets"].to_a).map do |image, facet|
        new(image: image, facet: facet, volumes: config["volumes"])
      end
    end

    attr_reader :image, :facet, :volumes, :name, :hash

    def initialize(image:, facet: nil, volumes: nil)
      @image = image
      @facet = facet
      @volumes = volumes || []
      assign_name
      assign_hash
    end

    def assign_name
      @name = @image.tr(":", "_") + ("-#{@facet[0]}" if @facet).to_s
    end

    def assign_hash
      @hash = Digest::SHA1.hexdigest(@image + @facet.to_s)
    end
  end
end
