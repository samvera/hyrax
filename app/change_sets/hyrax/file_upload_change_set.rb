module Hyrax
  class FileUploadChangeSet < Valkyrie::ChangeSet
    include VisibilityProperty
    property :files, virtual: true, multiple: true, required: false
    property :title, multiple: true, required: false
    property :label, multiple: true, required: false

    # Holds our current_ability and Blacklight repository
    property :search_context, virtual: true

    # Necessary for BrowseEverything?  This should probably move to a new change_set.
    property :import_url, virtual: true

    validate :validate_files

    # rubocop:disable Style/PredicateName
    def has_file?
      !file.nil?
    end
    # rubocop:enable Style/PredicateName

    delegate :user, to: :search_context

    def sync
      self.label ||= label_for(file)
      self.title = [label] if title.blank?

      super
    end

    private

      def label_for(file)
        file.original_filename
      end

      def file
        @file ||= files.detect { |f| f.respond_to?(:original_filename) }
      end

      def validate_files
        return errors.add('files', 'Error! No file uploaded') unless file
        errors.add('files', "#{file.original_filename} has no content! (Zero length file)") if empty_file?(file)
      end

      def empty_file?(file)
        (file.respond_to?(:tempfile) && file.tempfile.length == 0) ||
          (file.respond_to?(:size) && file.size == 0)
      end
  end
end
