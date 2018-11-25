# frozen_string_literal: true

require "fileutils"
require "tempfile"
require "tmpdir"
require "yaml"

class ExecutableMock
  Error = Class.new(StandardError)

  attr_reader :file_path, :path_setup

  def self.generate(name, mappings:, ruby_bin: RbConfig.ruby, directory: Dir.mktmpdir)
    instance = new(name, mappings: mappings, ruby_bin: ruby_bin, directory: directory)

    yield(instance).tap do |result|
      instance.finalize(result)
    end
  end

  def initialize(name, mappings:, ruby_bin: RbConfig.ruby, directory: Dir.mktmpdir)
    @mappings = mappings
    @ruby_bin = ruby_bin
    @file_path = File.join(directory, name)
    @path_setup = %(PATH="#{directory}:$PATH")

    write_executable(@file_path, contents: executable_contents)
  end

  def finalize(result = nil)
    argvs_map = YAML.safe_load(File.read(counter_cache_path))
    check_uncalled_argvs(argvs_map)
    check_mismatched_argvs_calls(argvs_map)
    FileUtils.rm(counter_cache_path)
  rescue Error
    puts result
    raise
  end

  def check_uncalled_argvs(argvs_map)
    uncalled_argvs = argvs_map.select { |_, v| v == 0 }

    raise(Error, <<~MESSAGE) if uncalled_argvs.any?
      The following argvs were not called:
      #{uncalled_argvs.keys.join("\n")}
    MESSAGE
  end

  def check_mismatched_argvs_calls(argvs_map)
    mismatched_argvs_calls = @mappings.select do |argv, outputs|
      outputs.is_a?(Array) && outputs.size != argvs_map[argv]
    end

    raise(Error, <<~MESSAGE) if mismatched_argvs_calls.any?
      The following argvs were not called the correct number of times:
      #{mismatched_argvs_calls.inspect}
    MESSAGE
  end

  def counter_cache_path
    @counter_cache_path ||= begin
      Tempfile.new.path.tap do |file_path|
        yaml_string = @mappings.to_h { |key, _| [key, 0] }.to_yaml
        File.open(file_path, "w") do |file|
          file.write(yaml_string)
        end
      end
    end
  end

  def write_executable(file_path, contents:)
    File.open(file_path, "w") do |file|
      file.write(contents)
    end
    File.chmod(0o755, file_path)
  end

  def executable_contents
    <<~TXT
      #!#{@ruby_bin}
      #{executable_mappings}
      #{executable_counter_cache_handler}
      #{executable_outputer}
    TXT
  end

  def executable_mappings
    <<~RUBY
      mappings = #{@mappings}
      argv_key = ARGV.join(" ")
      unless mappings.key?(argv_key)
        puts "ExecutableMock error: This executable does not support these args: '\#{argv_key}'"
        exit 1
      end
    RUBY
  end

  def executable_counter_cache_handler
    <<~RUBY
      require "yaml"
      call_count = nil
      File.open("#{counter_cache_path}", "a+") do |file|
        file.rewind
        counter_cache = YAML.load(file.read)
        call_count = counter_cache[argv_key]
        counter_cache[argv_key] += 1
        file.truncate(0)
        file.write(counter_cache.to_yaml)
      end
    RUBY
  end

  def executable_outputer
    <<~RUBY
      if mappings[argv_key].is_a?(Array)
        print mappings[argv_key].fetch(call_count)
      else
        print mappings[argv_key]
      end
    RUBY
  end
end
