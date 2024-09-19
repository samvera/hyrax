# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      ##
      # Adds logo info via `ChangeSet`.
      #
      # During the update collection process this step is called to update the file(s)
      # to be used as logo(s) for the collection.
      #
      class SaveCollectionLogo
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [Array<#Integer>] update_logo_file_ids
        # @param [Array<String>] alttext_values
        # @param [Array<String>] linkurl_values
        #
        # @return [Dry::Monads::Result] `Failure` if the work fails to save;
        #   `Success(input)`, otherwise.
        def call(collection_resource, update_logo_file_ids: nil, alttext_values: nil, linkurl_values: nil, logo_unchanged_indicator: true)
          return Success(collection_resource) if ActiveModel::Type::Boolean.new.cast(logo_unchanged_indicator)
          collection_id = collection_resource.id.to_s
          process_logo_input(collection_id: collection_id, update_logo_file_ids: update_logo_file_ids, alttext_values: alttext_values, linkurl_values: linkurl_values)
          Success(collection_resource)
        end

        private

        def process_logo_input(collection_id:, update_logo_file_ids:, alttext_values:, linkurl_values:)
          uploaded_file_ids = update_logo_file_ids
          public_files = []

          if uploaded_file_ids.nil?
            # all logo files were removed, so delete all files previously uploaded
            remove_redundant_files(collection_id: collection_id, public_files: public_files)
            return
          end

          public_files = process_logo_records(collection_id: collection_id, uploaded_file_ids: uploaded_file_ids, alttext_values: alttext_values, linkurl_values: linkurl_values)
          remove_redundant_files(collection_id: collection_id, public_files: public_files)
        end

        def process_logo_records(collection_id:, uploaded_file_ids:, alttext_values:, linkurl_values:)
          public_files = []
          uploaded_file_ids.each_with_index do |ufi, i|
            # If the user has chosen a new logo, the ufi will be an integer
            # If the logo was previously chosen, the ufi will be a path
            # If it is a path, update the rec, else create a new rec
            if !ufi.match(/\D/).nil?
              update_logo_info(collection_id: collection_id, uploaded_file_id: ufi, alttext: alttext_values[i], linkurl: verify_linkurl(linkurl_values[i]))
              public_files << ufi
            else # brand new one, insert in the database
              logo_info = create_logo_info(collection_id: collection_id, uploaded_file_id: ufi, alttext: alttext_values[i], linkurl: verify_linkurl(linkurl_values[i]))
              public_files << logo_info.local_path
            end
          end
          public_files
        end

        def update_logo_info(collection_id:, uploaded_file_id:, alttext:, linkurl:)
          logo_info = CollectionBrandingInfo.where(collection_id: collection_id).where(role: "logo").where(local_path: uploaded_file_id.to_s).first
          logo_info.alt_text = alttext
          logo_info.target_url = linkurl
          logo_info.local_path = uploaded_file_id
          logo_info.save(uploaded_file_id, false)
        end

        def create_logo_info(collection_id:, uploaded_file_id:, alttext:, linkurl:)
          file = uploaded_files(uploaded_file_id)
          logo_info = CollectionBrandingInfo.new(
            collection_id: collection_id,
            filename: File.split(file.file_url).last,
            role: "logo",
            alt_txt: alttext,
            target_url: linkurl
          )
          logo_info.save file.file_url
          logo_info
        end

        def uploaded_files(uploaded_file_ids)
          return [] if uploaded_file_ids.empty?
          UploadedFile.find(uploaded_file_ids)
        end

        def remove_redundant_files(collection_id:, public_files:)
          # remove any public ones that were not included in the selection.
          logos_info = CollectionBrandingInfo.where(collection_id: collection_id).where(role: "logo")
          logos_info.each do |logo_info|
            logo_info.delete(logo_info.local_path) unless public_files.include? logo_info.local_path
            logo_info.destroy unless public_files.include? logo_info.local_path
          end
        end

        # Only accept HTTP|HTTPS urls;
        # @return <String> the url
        def verify_linkurl(linkurl)
          url = Loofah.scrub_fragment(linkurl, :prune).to_s
          url if valid_url?(url)
        end

        def valid_url?(url)
          (url =~ URI.regexp(['http', 'https']))
        end
      end
    end
  end
end
