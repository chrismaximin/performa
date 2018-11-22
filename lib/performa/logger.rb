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

  class << LOG
    def info_success(message)
      LOG.info(message.colorize(:green))
    end

    def info_error(message)
      LOG.info(message.colorize(:red))
    end

    def info_warning(message)
      LOG.info(message.colorize(:yellow))
    end

    def info_notice(message)
      LOG.info(message.colorize(:light_blue))
    end
  end
end
