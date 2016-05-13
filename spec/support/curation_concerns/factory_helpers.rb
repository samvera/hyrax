module CurationConcerns
  module FactoryHelpers
    module_function

    def load_factories_for(context, klass)
      context.instance_exec(klass) do |curation_concern_class|
        let(:curation_concern_type_underscore) { curation_concern_class.name.underscore }
        let(:default_work_factory_name) { curation_concern_type_underscore }
        let(:default_work_factory_name_with_files) { "#{default_work_factory_name}_with_files".to_sym }
        let(:private_work_factory_name) { "private_#{curation_concern_type_underscore}".to_sym }
        let(:public_work_factory_name) { "public_#{curation_concern_type_underscore}".to_sym }
      end
    end

    def mock_file_factory(opts = {})
      mock_model('MockFile',
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
                 digest:            opts.fetch(:digest, [])
                )
    end
  end
end
