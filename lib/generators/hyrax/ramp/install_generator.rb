# frozen_string_literal: true
require 'rails/generators'

module Hyrax
  module Ramp
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      desc 'Install Ramp IIIF A/V player with React and jsbundling-rails'

      def install_dependencies
        gem 'jsbundling-rails' unless gem_exists?('jsbundling-rails')
        gem 'react_on_rails', '~> 14.0' unless gem_exists?('react_on_rails')

        Bundler.with_unbundled_env do
          run 'bundle install'
        end
      end

      def javascript_install
        # Check if webpack packages are installed
        package_json = JSON.parse(File.read('package.json'))
        return if package_json.dig('devDependencies', 'webpack')

        rails_command 'javascript:install:webpack'
      end

      def copy_webpack_config
        copy_file 'webpack.config.js', 'webpack.config.js', force: true
      end

      def setup_babel
        return if File.exist?('babel.config.js')

        copy_file 'babel.config.js', 'babel.config.js'
      end

      def add_react_dependencies
        run 'yarn add react@^18.2.0 react-dom@^18.2.0 react-on-rails @babel/core @babel/preset-env @babel/preset-react babel-loader'
      end

      def add_ramp_dependencies
        run 'yarn add @samvera/ramp@4.0.2 video.js@^8.10.0 style-loader css-loader'
      end

      def copy_ramp_component
        empty_directory 'app/javascript/components' unless File.directory?('app/javascript/components')
        copy_file 'RampPlayer.jsx', 'app/javascript/components/RampPlayer.jsx'
      end

      def create_ramp_bundle
        copy_file 'ramp.js', 'app/javascript/ramp.js'
      end

      def add_to_assets_precompile
        append_to_file 'config/initializers/assets.rb' do
          "\n# Precompile Ramp IIIF A/V player bundle\nRails.application.config.assets.precompile += %w[ramp.js]\n"
        end
      end

      # rubocop:disable Metrics/MethodLength
      def configure_iiif_av_viewer
        hyrax_config = 'config/initializers/hyrax.rb'

        unless File.exist?(hyrax_config)
          say 'config/initializers/hyrax.rb not found', :yellow
          say 'Please manually add: config.iiif_av_viewer = :ramp', :yellow
          return
        end

        content = File.read(hyrax_config)

        if content.match?(/config\.iiif_av_viewer\s*=/)
          # Already configured - update it
          gsub_file hyrax_config,
                    /config\.iiif_av_viewer\s*=\s*.+/,
                    'config.iiif_av_viewer = :ramp'
          say 'Updated config.iiif_av_viewer to :ramp', :green
        elsif content.include?('Hyrax.config do |config|')
          # Not configured yet - add it
          inject_into_file hyrax_config, after: "Hyrax.config do |config|\n" do
            <<~RUBY
              # IIIF AV viewer configuration
              # Use :ramp for audio/video content
              config.iiif_av_viewer = :ramp

            RUBY
          end
          say 'Added config.iiif_av_viewer = :ramp to Hyrax config', :green
        else
          say 'Could not configure iiif_av_viewer automatically', :yellow
          say 'Please manually add: config.iiif_av_viewer = :ramp', :yellow
        end
      end
      # rubocop:enable Metrics/MethodLength

      def build_ramp_bundle
        say 'Building Ramp bundle...', :green
        run 'yarn build'

        # Remove application.js if it was built (we use Sprockets for that)
        return unless File.exist?('app/assets/builds/application.js')

        remove_file 'app/assets/builds/application.js'
        say 'Removed webpack-built application.js (using Sprockets instead)', :yellow
      end

      def display_readme
        readme 'README' if behavior == :invoke
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
