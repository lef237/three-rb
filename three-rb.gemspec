require_relative "lib/three/version"

Gem::Specification.new do |spec|
  spec.name = "three-rb"
  spec.version = Three::VERSION
  spec.authors = ["LEF"]
  spec.email = []

  spec.summary = "Ruby 3D library inspired by three.js."
  spec.description = "three-rb provides Ruby APIs for building 3D scenes, with browser rendering through ruby.wasm and three.js."
  spec.homepage = "https://github.com/lef237/three-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("{exe,lib,docs,examples}/**/*") + %w[CHANGELOG.md LICENSE README.md package.json pnpm-lock.yaml]
  spec.bindir = "exe"
  spec.executables = ["three-rb"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 6.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
