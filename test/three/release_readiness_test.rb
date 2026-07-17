# frozen_string_literal: true

require "test_helper"

class ThreeReleaseReadinessTest < Minitest::Test
  ROOT = File.expand_path("../..", __dir__)

  def test_readme_documents_public_scope_and_release_checks
    readme = File.read(File.join(ROOT, "README.md"))

    assert_includes readme, "Browser-first alpha scope"
    assert_includes readme, "gem install three-rb"
    assert_includes readme, "bundle exec rake release:gem_smoke"
    assert_includes readme, "bundle exec rake release:preflight"
    assert_includes readme, "docs/release-readiness.md"
    assert_includes readme, "docs/next-work.md"
    assert_includes readme, "docs/browser-runtime.md"
    assert_includes readme, "docs/publishing.md"
    assert_includes readme, "examples/browser/README.md"
  end

  def test_changelog_and_release_docs_are_packaged
    spec = Gem::Specification.load(File.join(ROOT, "three-rb.gemspec"))

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

  def test_changelog_tracks_current_alpha_surface
    changelog = File.read(File.join(ROOT, "CHANGELOG.md"))

    assert_includes changelog, "## 0.1.0 - 2026-05-15"
    assert_includes changelog, "physical, matcap, toon, normal, shadow, line, points, and sprite materials"
    assert_includes changelog, "glTF/DRACO"
    assert_includes changelog, "loaded-asset traversal/disposal helpers"
    assert_includes changelog, "three-rb browser"
    assert_includes changelog, "avoid application-level"
    assert_includes changelog, "DotScreenPass"
    assert_includes changelog, "OutputPass"
    assert_includes changelog, "Deterministic JSON fixture regression coverage"
    assert_includes changelog, "installed executable"
    assert_includes changelog, "generated browser app"
  end

  def test_browser_runtime_guide_documents_boot_contract
    guide = File.read(File.join(ROOT, "docs/browser-runtime.md"))

    assert_includes guide, "ruby.wasm"
    assert_includes guide, "Three::Renderers::ThreeJSRenderer"
    assert_includes guide, "@ruby/3.4-wasm-wasi@2.9.4-2026-05-11-a"
    assert_includes guide, "three@0.185.1"
    assert_includes guide, "globalThis.THREE"
    assert_includes guide, "globalThis.THREE_GLTF_LOADER"
    assert_includes guide, "globalThis.THREE_DOT_SCREEN_PASS"
    assert_includes guide, "globalThis.THREE_OUTPUT_PASS"
    assert_includes guide, "missing `globalThis.THREE_*`"
    assert_includes guide, "import/assignment lines"
    assert_includes guide, "examples/browser/shared/boot.mjs"
    assert_includes guide, "Three::Browser.run"
    assert_includes guide, "app.on_key"
    assert_includes guide, "app.on_pointer"
    assert_includes guide, "app.pointer_ndc"
    assert_includes guide, "app.storage"
    assert_includes guide, "app.animation_loop"
    assert_includes guide, "Three::Browser.js"
    assert_includes guide, "three-rb browser examples/browser/quickstart"
    assert_includes guide, "three-rb browser examples/browser/ruby"
    assert_includes guide, "JavaScript Escape Hatch"
    assert_includes guide, "examples/browser/README.md"
    assert_includes guide, "docs/release-readiness.md"
    assert_includes guide, "docs/publishing.md"
    assert_includes guide, "Current Limits"
  end

  def test_next_work_records_resume_point
    next_work = File.read(File.join(ROOT, "docs/next-work.md"))

    assert_includes next_work, "public API and documentation consistency pass"
    assert_includes next_work, "Ruby-only entrypoints"
    assert_includes next_work, "three-rb browser"
    assert_includes next_work, "installed executable"
    assert_includes next_work, "current changelog heading"
    assert_includes next_work, "publishing checklist"
    assert_includes next_work, "Browser runtime guide"
    assert_includes next_work, "Browser examples overview"
    assert_includes next_work, "Saved JSON export/load fixture regression coverage"
    assert_includes next_work, "Do not start Phase 9 native renderer work yet"
  end

  def test_gemspec_has_public_metadata
    spec = Gem::Specification.load(File.join(ROOT, "three-rb.gemspec"))

    assert_equal "three-rb", spec.name
    assert_includes spec.files, "exe/three-rb"
    assert_includes spec.executables, "three-rb"
    assert_equal spec.homepage, spec.metadata.fetch("homepage_uri")
    assert_match(%r{/tree/main\z}, spec.metadata.fetch("source_code_uri"))
    assert_match(%r{/CHANGELOG\.md\z}, spec.metadata.fetch("changelog_uri"))
    assert_match(%r{/issues\z}, spec.metadata.fetch("bug_tracker_uri"))
    assert_equal "true", spec.metadata.fetch("rubygems_mfa_required")
  end

  def test_ci_runs_gem_install_smoke
    ci = File.read(File.join(ROOT, ".github/workflows/ci.yml"))
    smoke = File.read(File.join(ROOT, "test/release/gem_install_smoke.rb"))

    assert_includes ci, "bundle exec rake release:gem_smoke"
    assert_includes smoke, "three-rb"
    assert_includes smoke, "Three::Browser.run"
    assert_includes smoke, "expected generated Ruby to avoid require js"
  end

  def test_publishing_verifies_public_browser_generator
    publishing = File.read(File.join(ROOT, "docs/publishing.md"))

    assert_includes publishing, "three-rb --help"
    assert_includes publishing, "three-rb browser examples/browser/quickstart"
    assert_includes publishing, "three-rb browser examples/browser/ruby"
    assert_includes publishing, "examples/browser/ruby/assets/studio.hdr"
    assert_includes publishing, "generated Ruby entrypoint is Ruby-only"
    assert_includes publishing, "generated Ruby entrypoint used JS bridge"
  end

  def test_rakefile_exposes_release_preflight
    rakefile = File.read(File.join(ROOT, "Rakefile"))

    assert_includes rakefile, "task preflight:"
    assert_includes rakefile, "\"pnpm\", \"test:browser\""
  end
end
