# frozen_string_literal: true

require "tmpdir"
require "tempfile"
require "support/executable_mock"
require "digest"

RSpec.describe "Performa executable" do
  EXECUTABLE = File.join(Gem::Specification.find_by_name("performa").gem_dir, "exe", "performa")

  context "with stages (cached)" do
    it "runs command on the product of images * stages" do
      config = {
        "images" => ["ruby:0.0", "ruby:1.1"],
        "stages" => {
          "ar0" => ["gem install ar -v=0"],
          "ar1" => ["gem install ar -v=1"]
        }
      }
      config_file_path = setup_config_file(config)
      envs_hashes = generate_envs_hashes(config)

      docker_mappings = {
        "images -q performa_env:#{envs_hashes[0]}" => "some-image",
        "images -q performa_env:#{envs_hashes[1]}" => "some-image",
        "images -q performa_env:#{envs_hashes[2]}" => "some-image",
        "images -q performa_env:#{envs_hashes[3]}" => "some-image",

        "run -d performa_env:#{envs_hashes[0]} tail -f /dev/null" => "c00-ar0",
        "run -d performa_env:#{envs_hashes[1]} tail -f /dev/null" => "c00-ar1",
        "run -d performa_env:#{envs_hashes[2]} tail -f /dev/null" => "c11-ar0",
        "run -d performa_env:#{envs_hashes[3]} tail -f /dev/null" => "c11-ar1",

        "container exec c00-ar0 sh -c\ /the_command" => "result for c00-ar0",
        "container exec c00-ar1 sh -c\ /the_command" => "result for c00-ar1",
        "container exec c11-ar0 sh -c\ /the_command" => "result for c11-ar0",
        "container exec c11-ar1 sh -c\ /the_command" => "result for c11-ar1",

        "kill c00-ar0" => "",
        "kill c00-ar1" => "",
        "kill c11-ar0" => "",
        "kill c11-ar1" => ""
      }

      result = ExecutableMock.generate("docker", mappings: docker_mappings) do |mock|
        run_executable(
          config_file_path: config_file_path,
          command_prefix: mock.path_setup
        )
      end

      expect(result).to include("Output for ruby_0.0-ar0")
      expect(result).to include("result for c00-ar0")

      expect(result).to include("Output for ruby_0.0-ar1")
      expect(result).to include("result for c00-ar1")

      expect(result).to include("Output for ruby_1.1-ar0")
      expect(result).to include("result for c11-ar0")

      expect(result).to include("Output for ruby_1.1-ar1")
      expect(result).to include("result for c11-ar1")
    end
  end

  context "with stages (nothing cached + one env skipped)" do
    it "runs command on the product of images * stages - excluded" do
      config = {
        "images" => ["ruby:0.0", "ruby:1.1"],
        "stages" => {
          "ar0" => ["gem install ar -v=0"],
          "ar1" => ["gem install ar -v=1"]
        },
        "skip" => {
          "ruby:1.1" => ["ar0"]
        }
      }
      config_file_path = setup_config_file(config)
      envs_hashes = generate_envs_hashes(config)

      docker_mappings = {
        "images -q ruby:0.0" => "",
        "pull ruby:0.0" => "",
        "run -d ruby:0.0 tail -f /dev/null" => ["container-ruby00", "container-ruby00-v2"],

        "images -q performa_env:#{envs_hashes[0]}" => "",
        "commit container-ruby00 performa_env:#{envs_hashes[0]}" => "",

        "container exec container-ruby00 sh -c gem\ install\ ar\ -v\=0" => "",
        "container exec container-ruby00 sh -c /the_command" => "result for container-ruby00",
        "kill container-ruby00" => "",

        "images -q performa_env:#{envs_hashes[1]}" => "",
        "commit container-ruby00-v2 performa_env:#{envs_hashes[1]}" => "",

        "container exec container-ruby00-v2 sh -c gem\ install\ ar\ -v\=1" => "",
        "container exec container-ruby00-v2 sh -c /the_command" => "result for container-ruby00-v2",
        "kill container-ruby00-v2" => "",

        "images -q ruby:1.1" => "",
        "pull ruby:1.1" => "",
        "run -d ruby:1.1 tail -f /dev/null" => "container-ruby11-v2",

        "images -q performa_env:#{envs_hashes[3]}" => "",
        "commit container-ruby11-v2 performa_env:#{envs_hashes[3]}" => "",

        "container exec container-ruby11-v2 sh -c gem\ install\ ar\ -v\=1" => "",
        "container exec container-ruby11-v2 sh -c /the_command" => "result for container-ruby11-v2",
        "kill container-ruby11-v2" => ""
      }

      result = ExecutableMock.generate("docker", mappings: docker_mappings) do |mock|
        run_executable(
          config_file_path: config_file_path,
          command_prefix: mock.path_setup
        )
      end

      expect(result).to include("Output for ruby_0.0-ar0")
      expect(result).to include("result for container-ruby00")

      expect(result).to include("Output for ruby_0.0-ar1")
      expect(result).to include("result for container-ruby00-v2")

      expect(result).to include("Output for ruby_1.1-ar1")
      expect(result).to include("result for container-ruby11-v2")
    end
  end

  context "with no stages" do
    it "runs command on all the images" do
      config_file_path = setup_config_file("images" => ["ruby:0.0"])
      docker_mappings = {
        "images -q ruby:0.0" => "",
        "pull ruby:0.0" => "",
        "run -d ruby:0.0 tail -f /dev/null" => "container-ruby00",
        "container exec container-ruby00 sh -c /the_command" => "result for container-ruby00",
        "kill container-ruby00" => ""
      }

      result = ExecutableMock.generate("docker", mappings: docker_mappings) do |mock|
        run_executable(
          config_file_path: config_file_path,
          command_prefix: mock.path_setup
        )
      end

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

def generate_envs_hashes(config)
  config["images"].product(config["stages"].to_a).map do |product|
    Digest::SHA1.hexdigest(product.map(&:to_s).join)
  end
end
