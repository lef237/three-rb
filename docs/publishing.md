# Publishing

This is the manual release checklist for publishing `three-rb` to RubyGems.

`three-rb` is the RubyGems package name. The public Ruby require path is `three`, with `three-rb` kept as a compatibility require shim.

Do not publish until the release owner has confirmed:

- The target version.
- The release date for `CHANGELOG.md`.
- RubyGems credentials with MFA enabled.

## Release Checklist

Run these commands from the repository root.

```sh
cd /path/to/three-rb
```

Choose the target version before starting. If this is not already the version in `lib/three/version.rb`, update that file first.

```ruby
module Three
  VERSION = "X.Y.Z"
end
```

Set the version being released from the code. All later commands use this value.

```sh
VERSION="$(ruby -Ilib -e 'require "three/version"; print Three::VERSION')"
GEM_FILE="three-rb-${VERSION}.gem"
TAG="v${VERSION}"
echo "$VERSION"
echo "$GEM_FILE"
echo "$TAG"
```

Start from the latest clean `main`:

```sh
git switch main
git pull --ff-only origin main
git status --short
```

`git status --short` should be empty before release metadata changes.

Install and audit the Node/browser dependencies:

```sh
pnpm install --frozen-lockfile --ignore-scripts
pnpm audit --audit-level moderate
pnpm audit signatures
pnpm exec playwright install chromium
```

Run the full non-publishing release gate:

```sh
bundle exec rake release:preflight
```

`release:preflight` runs Ruby tests, builds and installs the gem into a temporary `GEM_HOME`, runs the install smoke test, runs all browser smoke tests, and builds the gem. It does not publish anything.

Confirm release metadata:

```sh
test "$(ruby -Ilib -e 'require "three/version"; print Three::VERSION')" = "$VERSION"
```

The command must exit successfully. If it fails, fix `VERSION` or `lib/three/version.rb` before continuing. Do not build or publish a gem until the code version is the intended release version.

Update `CHANGELOG.md` from an unreleased heading to the final release date. Replace `$VERSION` with the actual version value:

```md
## $VERSION - YYYY-MM-DD
```

Run the full gate again after metadata changes:

```sh
bundle exec rake release:preflight
```

Commit the release metadata, including `lib/three/version.rb` when it changed. Do not add co-author trailers.

```sh
git status --short
git add -A
git commit -m "Prepare ${VERSION} release"
```

Build the exact gem artifact that will be pushed:

```sh
gem build three-rb.gemspec
```

The build output must include the selected version and gem file:

```text
Name: three-rb
Version: $VERSION
File: $GEM_FILE
```

Publish to RubyGems:

```sh
gem push "$GEM_FILE"
```

RubyGems MFA is required because the gemspec sets `rubygems_mfa_required`. If RubyGems reports that MFA must be enabled, enable MFA on the publishing account and rerun the same `gem push` command.

If `gem push` fails for any reason, stop. Do not create or push the git tag until RubyGems confirms the gem was registered.

After RubyGems prints a successful registration message, create and push the git tag:

```sh
git tag -a "$TAG" -m "Release ${VERSION}"
git push origin main
git push origin "$TAG"
```

Verify the public install path from a clean temporary directory:

```sh
tmpdir="$(mktemp -d)"
cd "$tmpdir"
gem install three-rb -v "$VERSION"
ruby -e 'require "three"; puts Three::VERSION'
ruby -e 'require "three-rb"; puts Three::VERSION'
three-rb --help
three-rb browser examples/browser/quickstart
test -f examples/browser/quickstart/main.rb
ruby -e 'main = File.read("examples/browser/quickstart/main.rb"); abort "generated Ruby entrypoint used JS bridge" if main.include?("require \"js\"") || main.include?("JS.global"); puts "generated Ruby entrypoint is Ruby-only"'
three-rb browser examples/browser/ruby
test -f examples/browser/ruby/main.rb
test -f examples/browser/ruby/assets/studio.hdr
```

Both Ruby commands must print:

```text
$VERSION
```

The `three-rb browser` command must create `examples/browser/quickstart/main.rb` and `examples/browser/ruby/main.rb`, and the final Ruby command must print:

```text
generated Ruby entrypoint is Ruby-only
```

Then update issue tracker or release notes with the published RubyGems URL:

```text
https://rubygems.org/gems/three-rb
```
