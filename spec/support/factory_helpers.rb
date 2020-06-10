# frozen_string_literal: true
module Hyrax
  module FactoryHelpers
    module_function

    FIELDS = { mime_type: 'text/plain',
               content: 'content',
               file_size: [],
               format_label: [],
               height: [],
               width: [],
               filename: [],
               well_formed: [],
               page_count: [],
               file_title: [],
               last_modified: [],
               original_checksum: [],
               alpha_channels: [],
               digest: [],
               duration: [],
               sample_rate: [],
               versions: [] }.freeze

    def mock_file_factory(opts = {})
      fields = FIELDS.each_with_object({}) do |(name, default), hsh|
        hsh[name] = opts.fetch(name, default)
      end

      mock_model('MockOriginal', fields)
    end
  end
end
