# frozen_string_literal: true

module Hyrax
  class IiifViewerGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument :viewer, type: :string

    def dest_root
      @dest_root ||= Rails.env.test? ? File.join(Hyrax::Engine.root, "tmp") : Rails.root
    end

    def copy_viewer_files
      viewer_path = Pathname.new(dest_root).join('public', viewer.to_s)
      directory(viewer.to_s, viewer_path)
      return unless behavior == :revoke && Dir.exist?(viewer_path)
      FileUtils.rmdir(viewer_path)
      say_status :remove, viewer_path, :red
    end

    def copy_partial
      filename = "_#{viewer}.html.erb"
      dest = Pathname.new(dest_root).join("app", "views", "hyrax", "base", "iiif_viewers", filename)
      copy_file(filename, dest)
    end

    def configure_viewer
      config = Pathname.new(dest_root).join("config", "initializers", "hyrax.rb")
      lastmatch = nil

      content = "\n  # Injected via `rails generate hyrax:iiif_viewer #{viewer}`\n" \
        "  config.iiif_av_viewer = :#{viewer}\n\n"

      File.open(config).each_line do |line|
        regex = /config.iiif_av_viewer = .*/
        if behavior == :revoke
          # When removing/revoking, we return nil if the line includes
          # our viewer name because we want to delete the line instead
          # of using it as the "after" anchor.
          lastmatch = line if line.match?(regex) && line.exclude?(viewer.to_s)
        elsif line.match?(regex)
          lastmatch = line
        end
      end
      anchor = lastmatch || "Hyrax.config do |config|\n"
      insert_into_file(config, content, after: anchor)
    end
  end
end
