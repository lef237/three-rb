require "rake/testtask"
require "fileutils"
require "tmpdir"

Rake::TestTask.new do |task|
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
end

namespace :release do
  desc "Build the gem, install it into a temporary GEM_HOME, and run the install smoke test"
  task :gem_smoke do
    spec = Gem::Specification.load("three.rb.gemspec")
    gem_file = "#{spec.name}-#{spec.version}.gem"
    smoke_path = File.expand_path("test/release/gem_install_smoke.rb", __dir__)

    FileUtils.rm_f(gem_file)
    run_release_command!(Gem.ruby, "-S", "gem", "build", "three.rb.gemspec")

    Dir.mktmpdir("three-rb-gem-smoke") do |dir|
      gem_home = File.join(dir, "gems")
      env = {
        "BUNDLE_BIN_PATH" => nil,
        "BUNDLE_GEMFILE" => nil,
        "BUNDLER_VERSION" => nil,
        "GEM_HOME" => gem_home,
        "GEM_PATH" => gem_home,
        "RUBYOPT" => nil,
        "RUBYLIB" => nil
      }

      run_release_command!(Gem.ruby, "-S", "gem", "install", "--local", "--install-dir", gem_home, "--no-document", gem_file, env: env)
      run_release_command!(Gem.ruby, smoke_path, env: env, chdir: dir)
    end
  end

  desc "Run Ruby tests and release install smoke"
  task check: [:test, :gem_smoke]
end

task default: :test

def run_release_command!(*command, env: {}, chdir: nil)
  puts command.join(" ")
  runner = proc do
    if chdir
      Dir.chdir(chdir) { system(env, *command) }
    else
      system(env, *command)
    end
  end

  ok =
    if defined?(Bundler)
      Bundler.with_unbundled_env { runner.call }
    else
      runner.call
    end

  raise "command failed: #{command.join(" ")}" unless ok
end
