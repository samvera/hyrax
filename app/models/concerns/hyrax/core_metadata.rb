module Hyrax
  # These are the metadata elements that Hyrax internally requires of
  # all managed Collections, Works and FileSets will have.
  module CoreMetadata
    extend ActiveSupport::Concern

    included do
      attribute :id, Valkyrie::Types::ID.optional
      attribute :depositor, Valkyrie::Types::String
      attribute :title, Valkyrie::Types::Set

      def first_title
        title.first
      end

      # We reserve date_uploaded for the original creation date of the record.
      # For example, when migrating data from a fedora3 repo to fedora4,
      # fedora's system created date will reflect the date when the record
      # was created in fedora4, but the date_uploaded will preserve the
      # original creation date from the old repository.
      attribute :date_uploaded, Valkyrie::Types::DateTime

      attribute :date_modified, Valkyrie::Types::DateTime
    end
  end
end
