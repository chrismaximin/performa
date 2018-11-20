# frozen_string_literal: true

require "tempfile"
require "tmpdir"
require "yaml"

module ExecutableMock
  module_function

  def generate(name, inouts:, ruby_bin: RbConfig.ruby, directory: Dir.mktmpdir)
    counter_cache_path = setup_counter_cache(inouts)

    executable_contents = <<~TXT
      #!#{ruby_bin}
      #{executable_inouts(inouts)}
      #{executable_counter_cache_handler(counter_cache_path)}
      #{executable_outputer}
    TXT

    file_path = File.join(directory, name)
    write_executable(file_path, contents: executable_contents)

    {
      executable_path: file_path,
      counter_cache_path: counter_cache_path,
      path_setup: %(PATH="#{directory}:$PATH")
    }
  end

  def setup_counter_cache(inouts)
    Tempfile.new.path.tap do |file_path|
      yaml_string = inouts.to_h { |key, _| [key, 0] }.to_yaml
      File.open(file_path, "w") do |file|
        file.write(yaml_string)
      end
    end
  end

  def write_executable(file_path, contents:)
    File.open(file_path, "w") do |file|
      file.write(contents)
    end
    File.chmod(0o755, file_path)
  end

  def executable_inouts(inouts)
    <<~RUBY
      inouts = #{inouts}
      argv_key = ARGV.join(" ")
      unless inouts.key?(argv_key)
        puts "ExecutableMock error: This executable does not support these args: '\#{argv_key}'"
        exit 1
      end
    RUBY
  end

  def executable_counter_cache_handler(counter_cache_path)
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
      if inouts[argv_key].is_a?(Array)
        print inouts[argv_key].fetch(call_count)
      else
        print inouts[argv_key]
      end
    RUBY
  end
end
