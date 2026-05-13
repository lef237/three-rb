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
    assert_includes readme, "docs/publishing.md"
  end

  def test_changelog_and_release_readiness_docs_are_packaged
    spec = Gem::Specification.load(File.join(ROOT, "three.rb.gemspec"))

    assert_path_exists File.join(ROOT, "CHANGELOG.md")
    assert_path_exists File.join(ROOT, "docs/release-readiness.md")
    assert_path_exists File.join(ROOT, "docs/publishing.md")
    assert_includes spec.files, "CHANGELOG.md"
    assert_includes spec.files, "docs/release-readiness.md"
    assert_includes spec.files, "docs/publishing.md"
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
