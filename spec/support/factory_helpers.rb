module Hyrax
  module FactoryHelpers
    module_function

    def mock_file_factory(opts = {})
      mock_model('MockOriginal',
                 mime_type:         opts.fetch(:mime_type, 'text/plain'),
                 content:           opts.fetch(:content, 'content'),
                 file_size:         opts.fetch(:file_size, []),
                 format_label:      opts.fetch(:format_label, []),
                 height:            opts.fetch(:height, []),
                 width:             opts.fetch(:width, []),
                 filename:          opts.fetch(:filename, []),
                 well_formed:       opts.fetch(:well_formed, []),
                 page_count:        opts.fetch(:page_count, []),
                 file_title:        opts.fetch(:file_title, []),
                 last_modified:     opts.fetch(:last_modified, []),
                 original_checksum: opts.fetch(:original_checksum, []),
                 digest:            opts.fetch(:digest, []),
                 duration:          opts.fetch(:duration, []),
                 sample_rate:       opts.fetch(:sample_rate, []),
                 versions:          opts.fetch(:versions, []),
                 uri:               opts.fetch(:versions, []))
    end
  end
end
