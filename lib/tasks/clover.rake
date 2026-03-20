# frozen_string_literal: true

namespace :hyrax do
  namespace :clover do
    desc "Install and configure Clover IIIF viewer for audio/video files"
    task install: :environment do
      Hyrax::InstallIiifViewerService.install(:clover)
      puts "Clover IIIF viewer was installed and configured for
        audio and video. Run Hyrax::InstallIiifViewerService.remove(:clover)
        in the rails console to undo changes.".squish
    end
  end
end
