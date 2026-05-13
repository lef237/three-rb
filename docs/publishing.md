# Publishing

This document records the manual steps for publishing `three.rb`. Do not run the publish step until the release owner has confirmed the version, changelog date, and RubyGems credentials.

## Preflight

Start from a clean `main` branch:

```sh
git status --short
pnpm install --frozen-lockfile --ignore-scripts
pnpm audit --audit-level moderate
pnpm audit signatures
pnpm exec playwright install chromium
bundle exec rake release:preflight
```

`release:preflight` runs Ruby tests, builds and installs the gem into a temporary `GEM_HOME`, runs the install smoke test, runs all browser smoke tests, and builds the gem. It does not publish anything.

## Prepare Release Metadata

For version `0.1.0`:

1. Confirm `lib/three/version.rb` contains `VERSION = "0.1.0"`.
2. Change `CHANGELOG.md` from `## 0.1.0 - Unreleased` to the release date.
3. Run `bundle exec rake release:preflight` again.
4. Commit the metadata update:

```sh
git add CHANGELOG.md lib/three/version.rb
git commit -m "Prepare 0.1.0 release"
```

Skip `lib/three/version.rb` in the commit if the version was already correct.

## Publish

Publishing requires RubyGems credentials with MFA enabled.

```sh
gem build three.rb.gemspec
gem push three.rb-0.1.0.gem
```

After RubyGems accepts the gem, create and push the git tag:

```sh
git tag -a v0.1.0 -m "Release 0.1.0"
git push origin main
git push origin v0.1.0
```

If `gem push` fails, do not create the tag until the published artifact is confirmed.

## Post-publish

Verify the public install path from a clean temporary directory:

```sh
gem install three.rb -v 0.1.0
ruby -e 'require "three"; puts Three::VERSION'
```

Then update issue tracker or release notes with the published RubyGems URL.
