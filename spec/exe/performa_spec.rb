# frozen_string_literal: true

require "tmpdir"
require "tempfile"
require "support/executable_mock"
require "digest"

RSpec.describe "Performa executable" do
  EXECUTABLE = File.join(Gem::Specification.find_by_name("performa").gem_dir, "exe", "performa")

  context "with stages" do
    it "runs command on the product of images * stages" do
      config = {
        "images" => ["ruby:0.0", "ruby:1.1"],
        "stages" => {
          "ar0" => ["get install ar -v=0"],
          "ar1" => ["get install ar -v=1"]
        }
      }
      config_file_path = setup_config_file(config)

      envs_hashes = config["images"].product(config["stages"].to_a).map { |product| Digest::SHA1.hexdigest(product[0] + product[1].to_s)  }

      docker_inouts = {
        "images -q ruby:0.0" => "",
        "pull ruby:0.0" => "",
        "run -d ruby:0.0 tail -f /dev/null" => ["container-ruby00", "container-ruby00-v2"],

        "images -q performa_env:#{envs_hashes[0]}" => "",
        "commit container-ruby00 performa_env:#{envs_hashes[0]}" => "",

        "container exec container-ruby00 get install ar -v=0" => "",
        "container exec container-ruby00 /the_command" => "result for container-ruby00",
        "kill container-ruby00" => "",

        "images -q performa_env:#{envs_hashes[1]}" => "",
        "commit container-ruby00-v2 performa_env:#{envs_hashes[1]}" => "",

        "container exec container-ruby00-v2 get install ar -v=1" => "",
        "container exec container-ruby00-v2 /the_command" => "result for container-ruby00-v2",
        "kill container-ruby00-v2" => "",

        "images -q ruby:1.1" => "",
        "pull ruby:1.1" => "",
        "run -d ruby:1.1 tail -f /dev/null" => ["container-ruby11", "container-ruby11-v2"],

        "images -q performa_env:#{envs_hashes[2]}" => "",
        "commit container-ruby11 performa_env:#{envs_hashes[2]}" => "",

        "container exec container-ruby11 get install ar -v=0" => "",
        "container exec container-ruby11 /the_command" => "result for container-ruby11",
        "kill container-ruby11" => "",

        "images -q performa_env:#{envs_hashes[3]}" => "",
        "commit container-ruby11-v2 performa_env:#{envs_hashes[3]}" => "",

        "container exec container-ruby11-v2 get install ar -v=1" => "",
        "container exec container-ruby11-v2 /the_command" => "result for container-ruby11-v2",
        "kill container-ruby11-v2" => "",
      }

      exec_mock = ExecutableMock.generate("docker", inouts: docker_inouts)

      result = run_executable(
        config_file_path: config_file_path,
        command_prefix: exec_mock[:path_setup]
      )

      puts result.uncolorize

      expect(result).to include("Output for ruby_0.0-ar0")
      expect(result).to include("result for container-ruby00")

      expect(result).to include("Output for ruby_0.0-ar1")
      expect(result).to include("result for container-ruby00-v2")

      expect(result).to include("Output for ruby_1.1-ar0")
      expect(result).to include("result for container-ruby11")

      expect(result).to include("Output for ruby_1.1-ar1")
      expect(result).to include("result for container-ruby11-v2")

    end
  end

  context "with no stages" do
    it "runs command on all the images" do
      config_file_path = setup_config_file("images" => ["ruby:0.0"])
      docker_inouts = {
        "images -q ruby:0.0" => "",
        "pull ruby:0.0" => "",
        "run -d ruby:0.0 tail -f /dev/null" => "container-ruby00",
        "container exec container-ruby00 /the_command" => "result for container-ruby00",
        "kill container-ruby00" => "",
      }

      exec_mock = ExecutableMock.generate("docker", inouts: docker_inouts)

      result = run_executable(
        config_file_path: config_file_path,
        command_prefix: exec_mock[:path_setup]
      )

      puts result.uncolorize

      expect(result).to include("Output for ruby_0.0")
      expect(result).to include("result for container-ruby00")
    end
  end
end

def run_executable(config_file_path:, command_prefix: nil)
  command = %(#{command_prefix} #{EXECUTABLE} -c #{config_file_path})
  `#{command}`
end

def setup_config_file(config_hash)
  config_hash["version"] = 1
  config_hash["command"] = "/the_command"

  Tempfile.new.path.tap do |file_path|
    File.open(file_path, "w+") do |file|
      file.write(config_hash.to_yaml)
    end
  end
end
