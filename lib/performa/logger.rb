# frozen_string_literal: true

require "logger"
require "time"
require "colorize"

module Performa
  LOG = Logger.new(STDOUT)
  LOG.level = Logger::INFO
  LOG.formatter = proc do |severity, datetime, _progname, message|
    line = "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity} -- #{message}\n"

    case severity
    when "ERROR"
      line.colorize(:red)
    else
      line
    end
  end

  def LOG.success(message)
    LOG.info(message.colorize(:green))
  end
end
