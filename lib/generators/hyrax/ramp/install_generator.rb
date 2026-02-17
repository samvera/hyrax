# frozen_string_literal: true
require 'rails/generators'

module Hyrax
  module Ramp
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Install Ramp IIIF A/V player with React and Shakapacker"

      def install_dependencies
        gem 'shakapacker', '~> 8.0' unless gem_exists?('shakapacker')
        gem 'react-rails' unless gem_exists?('react-rails')

        Bundler.with_unbundled_env do
          run "bundle install"
        end
      end

      def add_package_manager_to_package_json
        package_json_path = 'package.json'
        return unless File.exist?(package_json_path)

        package_json = JSON.parse(File.read(package_json_path))
        return if package_json['packageManager']

        package_json['packageManager'] = 'yarn@1.22.22'
        File.write(package_json_path, JSON.pretty_generate(package_json))
        say "Added packageManager to package.json", :green
      end

      def shakapacker_install
        return if File.exist?('config/shakapacker.yml')
        rake "shakapacker:install"
      end

      def react_install
        return if File.exist?('app/javascript/packs/application.js')
        generate "react:install"
      end

      def setup_babel_config
        return if File.exist?('babel.config.js')
        copy_file 'babel.config.js', 'babel.config.js'
      end

      def add_ramp_yarn_dependency
        run "yarn add @samvera/ramp@4.0.2 react@^18.2.0 react-dom@^18.2.0 video.js@^8.10.0 react_ujs mini-css-extract-plugin css-loader style-loader"
      end

      def copy_ramp_react_component
        copy_file 'RampPlayer.jsx', 'app/javascript/components/RampPlayer.jsx'
      end

      def configure_iiif_av_viewer
        inject_into_file 'config/initializers/hyrax.rb',
                        "\n  # IIIF AV viewer configuration\n  # Use :ramp for audio/video content\n  config.iiif_av_viewer = :ramp\n",
                        after: "config.iiif_image_server = true\n"
      end

      def display_readme
        readme "README" if behavior == :invoke
      end

      private

      def gem_exists?(gem_name)
        Gem::Specification.find_by_name(gem_name)
      rescue Gem::MissingSpecError
        false
      end
    end
  end
end
