# frozen_string_literal: true

module Performa
  class ContainerId < String
    attr_accessor :from_cache

    def initialize(*args)
      @from_cache = false
      super
    end

    def self.from_cache(string)
      str = new(string)
      str.from_cache = true
      str
    end
  end
end
