# frozen_string_literal: true

module Maestry
  module ShellHelper
    def run_command(command,
      success_only: true,
      silent_command: false,
      silent_result: false)
      puts "#{'=' * 40}\nRunning `#{command}` ..." unless silent_command

      result = ""
      PTY.spawn(command) do |stdout, _stdin, _pid|
        stdout.each do |line|
          print(line) unless silent_result
          result += line
        end
      end

      begin
        Process.wait
      rescue Errno::ECHILD
        # There is no process to wait for
      end

      if success_only && !$CHILD_STATUS.success?
        raise "(non success exit code)"
      end

      result
    rescue StandardError => e
      raise Error, <<~MSG
        Error running the command `#{command}`:
        error => #{e.message}
        command output => #{result}
      MSG
    end
  end

  def pty_spawn(command); end
end
