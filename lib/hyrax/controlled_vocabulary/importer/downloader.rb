# frozen_string_literal: true
require 'ruby-progressbar'

module Hyrax
  module ControlledVocabulary
    module Importer
      class Downloader
        def self.fetch(url, output)
          open(url) do |io|
            IO.copy_stream(io, output)
          end
        rescue OpenURI::HTTPError => e
          raise "Unable to download from #{url}\n#{e.message}: #{e.io.read}"
        end
      end
    end
  end
end
