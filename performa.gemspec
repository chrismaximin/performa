# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "performa/version"

Gem::Specification.new do |spec|
  spec.name = "performa"
  spec.version = Performa::VERSION
  spec.authors = ["Christophe Maximin"]
  spec.email = ["christophe.maximin@gmail.com"]

  spec.summary = "PLACEHOLDER"
  spec.description = "PLACEHOLDER"
  spec.homepage = "https://github.com/christophemaximin/performa"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/christophemaximin/performa"
  spec.metadata["changelog_uri"] = "https://github.com/christophemaximin/performa/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "colorize", "~> 0.8"
end
