require 'rake/testtask'
require 'bundler'
Bundler::GemHelper.install_tasks

APP_ROOT= File.dirname(__FILE__)
require 'solr_wrapper'
require 'fcrepo_wrapper'
require 'active_fedora/rake_support'

desc "Run Continuous Integration"
task :ci do
  ENV['environment'] = "test"
  with_test_server do
    Rake::Task['spec'].invoke
  end
  Rake::Task["doc"].invoke
end

task :default => [:ci]

directory 'pkg'

FRAMEWORKS = ['hydra-access-controls', 'hydra-core']

root    = File.expand_path('../', __FILE__)
version = File.read("#{root}/HYDRA_VERSION").strip
tag     = "v#{version}"

(FRAMEWORKS  + ['hydra-head']).each do |framework|
  namespace framework do
    gem     = "pkg/#{framework}-#{version}.gem"
    gemspec = "#{framework}.gemspec"

    task :clean do
      rm_f gem
    end

    task :update_version_rb do
      glob = root.dup
      glob << "/#{framework}/lib/*" unless framework == "hydra-head"
      glob << "/version.rb"

      file = Dir[glob].first
      if file
        ruby = File.read(file)

        major, minor, tiny, pre = version.split('.')
        pre = pre ? pre.inspect : "nil"

        ruby.gsub!(/^(\s*)VERSION = ".*?"$/, "\\1VERSION = \"#{version}\"")
        raise "Could not insert VERSION in #{file}" unless $1
        File.open(file, 'w') { |f| f.write ruby }
      end
    end
    task gem => %w(update_version_rb pkg) do
      cmd = ""
      cmd << "cd #{framework} && " unless framework == "hydra-head"
      cmd << "gem build #{gemspec} && mv #{framework}-#{version}.gem #{root}/pkg/"
      sh cmd
    end

    task :build => [:clean, gem]
    task :install => :build do
      sh "gem install #{gem}"
    end

    task :prep_release => [:ensure_clean_state, :build]

    task :push => :build do
      sh "gem push #{gem}"
    end
  end
end

namespace :all do
  task :build   => FRAMEWORKS.map { |f| "#{f}:build"   } + ['hydra-head:build']
  task :install => FRAMEWORKS.map { |f| "#{f}:install" } + ['hydra-head:install']
  task :push    => FRAMEWORKS.map { |f| "#{f}:push"    } + ['hydra-head:push']

  task :ensure_clean_state do
    unless `git status -s | grep -v HYDRA_VERSION | grep -v HISTORY.textile`.strip.empty?
      abort "[ABORTING] `git status` reports a dirty tree. Make sure all changes are committed"
    end

    unless ENV['SKIP_TAG'] || `git tag | grep "#{tag}$"`.strip.empty?
      abort "[ABORTING] `git tag` shows that #{tag} already exists. Has this version already\n"\
            "           been released? Git tagging can be skipped by setting SKIP_TAG=1"
    end
  end

  task :commit do
    File.open('pkg/commit_message.txt', 'w') do |f|
      f.puts "# Preparing for #{version} release\n"
      f.puts
      f.puts "# UNCOMMENT THE LINE ABOVE TO APPROVE THIS COMMIT"
    end

    sh "git add . && git commit --verbose --template=pkg/commit_message.txt"
    rm_f "pkg/commit_message.txt"
  end

  task :tag do
    sh "git tag #{tag}"
    sh "git push --tags"
  end

  task :release => %w(ensure_clean_state build commit tag push)
end

desc "run all specs"
task :spec do
  raise "test failures" unless all_modules('rake spec')
end

desc "Remove any existing test deploys"
task :clean do
  raise "test failures" unless all_modules('rake clean')
end

def all_modules(cmd)
  FRAMEWORKS.each do |dir|
    Dir.chdir(dir) do
      puts "\n\e[1;33m[Hydra CI] #{dir}\e[m\n"
      #cmd = "bundle exec rake spec" # doesn't work because it doesn't require the gems specified in the Gemfiles of the test rails apps
      return false unless system(cmd)
    end
  end
end

begin
  require 'yard'
  require 'yard/rake/yardoc_task'
  project_root = File.expand_path(".")
  doc_destination = File.join(project_root, 'doc')
  if !File.exists?(doc_destination)
    FileUtils.mkdir_p(doc_destination)
  end

  YARD::Rake::YardocTask.new(:doc) do |yt|
    yt.files   = ['*/lib/**/*.rb', project_root+"*", '*/app/**/*.rb']

    yt.options << "-m" << "textile"
    yt.options << "--protected"
    yt.options << "--no-private"
    yt.options << "-r" << "README.textile"
    yt.options << "-o" << "doc"
    yt.options << "--files" << "*.textile"
  end
rescue LoadError
  desc "Generate YARD Documentation"
  task :doc do
    abort "Please install the YARD gem to generate rdoc."
  end
end
