# frozen_string_literal: true

require "test_helper"

class ThreeReleaseReadinessTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  def test_readme_documents_public_scope_and_release_checks
    readme = File.read(File.join(ROOT, "README.md"))

    assert_includes readme, "Browser-first alpha scope"
    assert_includes readme, "gem install three.rb"
    assert_includes readme, "bundle exec rake release:gem_smoke"
    assert_includes readme, "bundle exec rake release:preflight"
    assert_includes readme, "docs/release-readiness.md"
    assert_includes readme, "docs/next-work.md"
    assert_includes readme, "docs/browser-runtime.md"
    assert_includes readme, "docs/publishing.md"
    assert_includes readme, "examples/browser/README.md"
  end

  def test_changelog_and_release_docs_are_packaged
    spec = Gem::Specification.load(File.join(ROOT, "three.rb.gemspec"))

    assert_path_exists File.join(ROOT, "CHANGELOG.md")
    assert_path_exists File.join(ROOT, "docs/browser-runtime.md")
    assert_path_exists File.join(ROOT, "examples/browser/README.md")
    assert_path_exists File.join(ROOT, "docs/next-work.md")
    assert_path_exists File.join(ROOT, "docs/release-readiness.md")
    assert_path_exists File.join(ROOT, "docs/publishing.md")
    assert_includes spec.files, "CHANGELOG.md"
    assert_includes spec.files, "docs/browser-runtime.md"
    assert_includes spec.files, "examples/browser/README.md"
    assert_includes spec.files, "docs/next-work.md"
    assert_includes spec.files, "docs/release-readiness.md"
    assert_includes spec.files, "docs/publishing.md"
  end

  def test_browser_runtime_guide_documents_boot_contract
    guide = File.read(File.join(ROOT, "docs/browser-runtime.md"))

    assert_includes guide, "ruby.wasm"
    assert_includes guide, "Three::Renderers::ThreeJSRenderer"
    assert_includes guide, "@ruby/3.4-wasm-wasi@2.9.4-2026-05-11-a"
    assert_includes guide, "three@0.184.0"
    assert_includes guide, "globalThis.THREE"
    assert_includes guide, "globalThis.THREE_GLTF_LOADER"
    assert_includes guide, "examples/browser/shared/boot.mjs"
    assert_includes guide, "examples/browser/README.md"
    assert_includes guide, "docs/release-readiness.md"
    assert_includes guide, "docs/publishing.md"
    assert_includes guide, "Current Limits"
  end

  def test_next_work_records_resume_point
    next_work = File.read(File.join(ROOT, "docs/next-work.md"))

    assert_includes next_work, "Select the next browser-facing feature"
    assert_includes next_work, "Browser runtime guide"
    assert_includes next_work, "Browser examples overview"
    assert_includes next_work, "Saved JSON export/load fixture regression coverage"
    assert_includes next_work, "Do not start Phase 9 native renderer work yet"
  end

  def test_gemspec_has_public_metadata
    spec = Gem::Specification.load(File.join(ROOT, "three.rb.gemspec"))

    assert_equal spec.homepage, spec.metadata.fetch("homepage_uri")
    assert_match(%r{/tree/main\z}, spec.metadata.fetch("source_code_uri"))
    assert_match(%r{/CHANGELOG\.md\z}, spec.metadata.fetch("changelog_uri"))
    assert_match(%r{/issues\z}, spec.metadata.fetch("bug_tracker_uri"))
    assert_equal "true", spec.metadata.fetch("rubygems_mfa_required")
  end

  def test_ci_runs_gem_install_smoke
    ci = File.read(File.join(ROOT, ".github/workflows/ci.yml"))

    assert_includes ci, "bundle exec rake release:gem_smoke"
  end

  def test_rakefile_exposes_release_preflight
    rakefile = File.read(File.join(ROOT, "Rakefile"))

    assert_includes rakefile, "task preflight:"
    assert_includes rakefile, "\"pnpm\", \"test:browser\""
  end
end
