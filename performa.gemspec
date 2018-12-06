# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "performa/version"

Gem::Specification.new do |spec|
  spec.name = "performa"
  spec.version = Performa::VERSION
  spec.authors = ["Christophe Maximin"]
  spec.email = ["christophe.maximin@gmail.com"]
  spec.licenses = ["MIT"]

  spec.summary = "Performa allows you to quickly run a script on a combination of docker images and staging commands"
  spec.description = spec.summary
  spec.homepage = "https://github.com/christophemaximin/performa"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/christophemaximin/performa"
  spec.metadata["changelog_uri"] = "https://github.com/christophemaximin/performa/blob/master/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select { |f| f.match(%r{^(lib|exe)/}) }
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "colorize", "~> 0.8"
end
