module Worthwhile
  module CurationConcern
    class GenericFileActor 
      include CurationConcern::BaseActor

      def create
        super && update_file
      end

      def update
        super && update_file
      end

      def rollback
        update_version
      end

      protected
      def update_file
        file = attributes.delete(:file)
        title = attributes[:title]
        title ||= file.original_filename if file
        curation_concern.label = title
        if file
          CurationConcern.attach_file(curation_concern, user, file)
        else
          true
        end
      end

      def update_version
        version_to_revert = attributes.delete(:version)
        return true if version_to_revert.blank?
        return true if version_to_revert.to_s ==  curation_concern.current_version_id

        revision = curation_concern.content.get_version(version_to_revert)
        mime_type = revision.mimeType.empty? ? "application/octet-stream" : revision.mimeType
        options = { label: revision.label, mimeType: mime_type, dsid: 'content' }
        curation_concern.add_file_datastream(revision.content, options)
        curation_concern.record_version_committer(user)
        curation_concern.save
      end
    end
  end
end
