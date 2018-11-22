# frozen_string_literal: true

module Performa
  class CommandResult < String
    attr_accessor :success
    def success?
      @success
    end
  end
end
