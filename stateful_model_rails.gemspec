# frozen_string_literal: true

require_relative "lib/stateful_model_rails/version"

Gem::Specification.new do |spec|
  spec.name          = "stateful_model_rails"
  spec.version       = StatefulModelRails::VERSION
  spec.authors       = ["Ben Anderson"]
  spec.email         = ["benanderson@acidic.co.nz"]

  spec.summary       = "A tiny library for making ActiveRecord models into state machines"
  spec.homepage      = "https://github.com/bagedevimo/stateful-model-rails"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.1.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bagedevimo/stateful-model-rails"
  spec.metadata["changelog_uri"] = "https://github.com/bagedevimo/stateful-model-rails"

  spec.add_runtime_dependency "activerecord", ">= 5.2.0"
  spec.add_runtime_dependency "activesupport", ">= 5.2.0"

  spec.files = Dir["lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
end
