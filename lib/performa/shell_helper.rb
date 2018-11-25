# frozen_string_literal: true

require "English"
require "open3"

module Performa
  module ShellHelper
    def run_command(command, success_only: true, no_capture: false)
      LOG.info("Running `#{command.colorize(:light_yellow)}` ...")

      exit_status, result_str = no_capture ? run_no_capture_command(command) : run_capture_command(command)
      raise "(non-zero exit code: #{exit_status.exitstatus})" if success_only && !exit_status.success?

      CommandResult.new(result_str).tap do |result|
        result.success = exit_status.success?
      end
    rescue StandardError => e
      raise Error, <<~MSG
        Error running the command `#{command}`:
        => error: #{e.message}
        => command output: #{result_str}
      MSG
    end

    def run_no_capture_command(command)
      system(command)
      [$CHILD_STATUS, ""]
    end

    def run_capture_command(command)
      exit_status = nil
      result_str = +""

      Open3.popen2e(command) do |_stdin, stdout_and_stderr, wait_thr|
        stdout_and_stderr.each do |line|
          result_str << line
        end
        exit_status = wait_thr.value
      end
      exit_status.success? ? LOG.info_success(result_str) : LOG.info_error(result_str)

      [exit_status, result_str]
    end
  end
end
