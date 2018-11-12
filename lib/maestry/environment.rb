# frozen_string_literal: true

module Maestry
  class Environment
    attr_reader :image, :facet, :name
    attr_accessor :container_id

    def self.from_image(image)
      new.tap do |env|
        env.image = image
      end
    end

    def image=(image)
      @image = image
      set_name
    end

    def facet=(facet)
      @facet = facet
      set_name
    end

    def set_name
      @name = @image.tr(":", "_") + ("-#{@facet}" if @facet).to_s
    end
  end
end
