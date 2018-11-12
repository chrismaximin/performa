# frozen_string_literal: true

require "pty"
require "English"

module Maestry
  module ShellHelper
    def run_command(command, success_only: true)
      LOG.success("Running `#{command}` ...")
      result = pty_spawn(command)

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

      wait_for_child_process

      result
    end

    def wait_for_child_process
      Process.wait
    rescue Errno::ECHILD
      LOG.debug("There is no process to wait for") # TODO: do better?
    end
  end
end
