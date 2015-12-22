module Sufia
  module UploadSetBehavior
    extend ActiveSupport::Concern
    include Hydra::AccessControls::Permissions
    include CurationConcerns::Noid

    included do
      has_many :works, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf, class_name: 'ActiveFedora::Base'

      property :title, predicate: ::RDF::DC.title
      property :status, predicate: ::RDF::DC.type
    end

    module ClassMethods
      include CurationConcerns::Lockable

      # This method handles most race conditions gracefully.
      def find_or_create(id)
        acquire_lock_for(id) do
          begin
            UploadSet.find(id)
          rescue ActiveFedora::ObjectNotFoundError
            UploadSet.create(id: id)
          end
        end
      end
    end
  end
end
