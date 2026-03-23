# frozen_string_literal: true

# A reusable class for installing and configuring IIIF viewers.
# Example usage:

#   Hyrax::InstallIiifViewerService.install(:clover)

# will copy Clover IIIF viewer into your app/s public folder and
# configure your app to use them. Don't forget to enable IIIF
# A/V support in your settings dashboard!

# Call Hyrax::InstallIiifAvViewerService.remove(:clover) to undo
# these changes and clean up relevant files (this is useful for testing).

# This class leverages the rails/thor (https://github.com/rails/thor)
# gem's methods for creating, deleting, and editing files.
# rails/thor also provides idempotency and logging to stdout.

module Hyrax
  class InstallIiifViewerService < Thor::Group
    include Thor::Actions

    # @param viewer [Symbol] the name of the IIIF viewer to install.
    # Currently, the only accepted option is :clover, but we may add more.
    def self.install(viewer, options = {})
      instance = new(viewer, options)
      all_commands.keys.map(&:to_sym).each do |command|
        instance.send(command)
      end
    end

    def self.remove(viewer, options = {})
      instance = new(viewer, options.merge({ behavior: :revoke }))
      all_commands.keys.map(&:to_sym).each do |command|
        instance.send(command)
      end
    end

    # The directory to copy files from
    def self.source_root
      File.join(Hyrax::Engine.root, 'lib', 'generators', 'hyrax', 'templates', 'iiif_viewers')
    end

    # @param viewer [Symbol] the name of the IIIF viewer to install.
    # Currently, the only accepted option is :clover, but we may add more.
    def initialize(viewer, options = {})
      @viewer = viewer
      # If testing, copy files to tmp to avoid conflicts with dev env
      dest_root = Rails.env.test? ? File.join(Hyrax::Engine.root, "tmp") : Rails.root
      # See rails/thor gem - Thor::Base#initialize for superclass definition
      super([], {}, options.merge(destination_root: dest_root))
    end

    def copy_viewer_files
      viewer_path = Pathname.new(destination_root).join('public', @viewer.to_s)
      directory(@viewer.to_s, viewer_path)
      return unless behavior == :revoke && Dir.exist?(viewer_path)
      FileUtils.rmdir(viewer_path)
      say_status :remove, viewer_path, :red
    end

    def copy_partial
      filename = "_#{@viewer}.html.erb"
      dest = Pathname.new(destination_root).join("app", "views", "hyrax", "base", "iiif_viewers", filename)
      copy_file(filename, dest)
    end

    def configure_viewer
      config = Pathname.new(destination_root).join("config", "initializers", "hyrax.rb")
      lastmatch = nil

      content = "\n  # Injected via `rake hyrax:#{@viewer}:install`\n" \
        "  config.iiif_av_viewer = :#{@viewer}\n\n"

      File.open(config).each_line do |line|
        regex = /config.iiif_av_viewer = .*/
        if behavior == :revoke
          # When removing/revoking, we want to return nil if the
          # line includes our viewer name because we want to delete
          # the line instead of using it as the "after" anchor.
          lastmatch = line if line.match?(regex) && line.exclude?(@viewer.to_s)
        elsif line.match?(regex)
          lastmatch = line
        end
      end
      anchor = lastmatch || "Hyrax.config do |config|\n"
      insert_into_file(config, content, after: anchor)
    end
  end
end
