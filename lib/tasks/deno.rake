# frozen_string_literal: true
namespace :hyrax do
  namespace :deno do
    desc "Bundle Deno scripts"
    task :bundle, [:reload] => :environment do |_t, args|
      Dir.mkdir(Rails.root.join('public', 'scripts')) unless File.exist?(Rails.root.join('public', 'scripts'))
      hyrax_path = Gem.loaded_specs['hyrax'].full_gem_path
      deno_config = File.join(hyrax_path, 'deno.json').to_s
      deno_hyrax = File.join(hyrax_path, 'app', 'scripts', 'hyrax', 'mod.js').to_s
      deno_hyrax_bundle = Rails.root.join('public', 'scripts', 'hyrax.js').to_s
      if args.reload && !%w[0 no false].include?(args.reload)
        system 'bin/deno', 'bundle', '--config', deno_config, '-r', '--no-check=remote', deno_hyrax, deno_hyrax_bundle, exception: true
      else
        system 'bin/deno', 'bundle', '--config', deno_config, '--no-check=remote', deno_hyrax, deno_hyrax_bundle, exception: true
      end
      puts 'Hyrax Javascript assets bundled to public/scripts/hyrax.js.'
    end
    desc "Format Deno scripts"
    task fmt: :environment do
      hyrax_path = Gem.loaded_specs['hyrax'].full_gem_path
      deno_config = File.join(hyrax_path, 'deno.json').to_s
      system 'bin/deno', 'fmt', '--config', deno_config, exception: true
    end
    desc "Install bin/deno"
    task install: :environment do
      # Copy the files into place
      hyrax_templates_path = File.join(Gem.loaded_specs['hyrax'].full_gem_path, 'lib', 'generators', 'hyrax', 'templates')
      copy_file File.join(hyrax_templates_path, 'bin', 'deno'), Rails.root.join('bin', 'deno')
      puts 'bin/deno copied into place; make sure Deno is installed on your machine before running.'
    end
    desc "Lint Deno scripts"
    task lint: :environment do
      hyrax_path = Gem.loaded_specs['hyrax'].full_gem_path
      deno_config = File.join(hyrax_path, 'deno.json').to_s
      system 'bin/deno', 'lint', '--config', deno_config, exception: true
    end
    desc "Test Deno scripts"
    task :test, [:reload] => :environment do |_t, args|
      hyrax_path = Gem.loaded_specs['hyrax'].full_gem_path
      deno_scripts = File.join(hyrax_path, 'app', 'scripts').to_s
      deno_lib_scripts = File.join(hyrax_path, 'lib', 'scripts').to_s
      deno_config = File.join(hyrax_path, 'deno.json').to_s
      if args.reload && !%w[0 no false].include?(args.reload)
        system 'bin/deno', 'test', '--config', deno_config, '-r', '--no-check=remote', deno_scripts, deno_lib_scripts, exception: true
      else
        system 'bin/deno', 'test', '--config', deno_config, '--no-check=remote', deno_scripts, deno_lib_scripts, exception: true
      end
    end
  end
end
namespace :assets do
  task precompile: 'hyrax:deno:bundle'
end
