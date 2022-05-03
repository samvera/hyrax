# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # Adds banner info via `ChangeSet`.
      #
      # During the update collection process this step is called to update the file
      # to be used as a the banner for the collection.
      #
      class SaveCollectionBanner
        include Dry::Transaction::Operation

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [Array<Integer>] update_banner_file_ids
        # @param [Boolean] banner_unchanged_indicator
        #
        # @return [Dry::Monads::Result] `Failure` if the banner info fails to save;
        #   `Success(input)`, otherwise.
        def call(collection_resource, update_banner_file_ids: nil, banner_unchanged_indicator: true)
          return Success(collection_resource) if ActiveModel::Type::Boolean.new.cast(banner_unchanged_indicator)
          collection_id = collection_resource.id.to_s
          process_banner_input(collection_id: collection_id, update_banner_file_ids: update_banner_file_ids)
          Success(collection_resource)
        end

        private

        def process_banner_input(collection_id:, update_banner_file_ids:)
          remove_banner(collection_id: collection_id)
          add_new_banner(collection_id: collection_id, uploaded_file_ids: update_banner_file_ids) if update_banner_file_ids
        end

        def remove_banner(collection_id:)
          banner_info = CollectionBrandingInfo.where(collection_id: collection_id).where(role: "banner")
          banner_info&.delete_all
        end

        def add_new_banner(collection_id:, uploaded_file_ids:)
          f = uploaded_files(uploaded_file_ids).first
          banner_info = CollectionBrandingInfo.new(
            collection_id: collection_id,
            filename: File.split(f.file_url).last,
            role: "banner",
            alt_txt: "",
            target_url: ""
          )
          banner_info.save f.file_url
        end

        def uploaded_files(uploaded_file_ids)
          return [] if uploaded_file_ids.empty?
          UploadedFile.find(uploaded_file_ids)
        end
      end
    end
  end
end
