# frozen_string_literal: true

require "pty"
require "English"

module Performa
  module ShellHelper
    def run_command(command, success_only: true, no_capture: false)
      LOG.success("Running `#{command}` ...")

      if no_capture
        system(command)
        result = ""
      else
        result = pty_spawn(command)
      end

      raise "(non-zero exit code)" if success_only && !$CHILD_STATUS.success?

      result
    rescue StandardError => e
      raise Error, <<~MSG
        Error running the command `#{command}`:
        => error: #{e.message}
        => command output: #{result}
      MSG
    end

    def pty_spawn(command)
      result = +""
      PTY.spawn(command) do |stdout, _stdin, _pid|
        stdout.each do |line|
          LOG.info(line.strip)
          result << line
        end
      end

      Process.wait unless $CHILD_STATUS.exited?

      result
    end
  end
end
