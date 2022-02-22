# frozen_string_literal: true
module Hyrax
  module SolrDocument
    module Metadata
      extend ActiveSupport::Concern
      class_methods do
        def attribute(name, type, field)
          define_method name do
            type.coerce(self[field])
          end
        end
      end

      module Solr
        class Array
          # @return [Array]
          def self.coerce(input)
            ::Array.wrap(input)
          end
        end

        class String
          # @return [String]
          def self.coerce(input)
            ::Array.wrap(input).first
          end
        end

        class Date
          # @return [Date]
          def self.coerce(input)
            field = String.coerce(input)
            return if field.blank?
            begin
              ::Date.parse(field)
            rescue ArgumentError
              Hyrax.logger.info "Unable to parse date: #{field.first.inspect}"
            end
          end
        end
      end

      included do
        attribute :alternative_title, Solr::Array, "alternative_title_tesim"
        attribute :identifier, Solr::Array, "identifier_tesim"
        attribute :based_near, Solr::Array, "based_near_tesim"
        attribute :based_near_label, Solr::Array, "based_near_label_tesim"
        attribute :related_url, Solr::Array, "related_url_tesim"
        attribute :resource_type, Solr::Array, "resource_type_tesim"
        attribute :edit_groups, Solr::Array, ::Ability.edit_group_field
        attribute :edit_people, Solr::Array, ::Ability.edit_user_field
        attribute :read_groups, Solr::Array, ::Ability.read_group_field
        attribute :collection_ids, Solr::Array, 'collection_ids_tesim'
        attribute :admin_set, Solr::Array, "admin_set_tesim"
        attribute :admin_set_id, Solr::Array, "admin_set_id_ssim"
        attribute :member_ids, Solr::Array, "member_ids_ssim"
        attribute :member_of_collection_ids, Solr::Array, "member_of_collection_ids_ssim"
        attribute :member_of_collections, Solr::Array, "member_of_collections_ssim"
        attribute :description, Solr::Array, "description_tesim"
        attribute :abstract, Solr::Array, "abstract_tesim"
        attribute :title, Solr::Array, "title_tesim"
        attribute :contributor, Solr::Array, "contributor_tesim"
        attribute :subject, Solr::Array, "subject_tesim"
        attribute :publisher, Solr::Array, "publisher_tesim"
        attribute :language, Solr::Array, "language_tesim"
        attribute :keyword, Solr::Array, "keyword_tesim"
        attribute :license, Solr::Array, "license_tesim"
        attribute :source, Solr::Array, "source_tesim"
        attribute :date_created, Solr::Array, "date_created_tesim"
        attribute :rights_statement, Solr::Array, "rights_statement_tesim"
        attribute :rights_notes, Solr::Array, "rights_notes_tesim"
        attribute :access_right, Solr::Array, "access_right_tesim"
        attribute :mime_type, Solr::String, "mime_type_ssi"
        attribute :workflow_state, Solr::String, "workflow_state_name_ssim"
        attribute :human_readable_type, Solr::String, "human_readable_type_tesim"
        attribute :representative_id, Solr::String, "hasRelatedMediaFragment_ssim"
        # extract the term name from the rendering_predicate (it might be after the final / or #)
        attribute :rendering_ids, Solr::Array, Hyrax.config.rendering_predicate.value.split(/#|\/|,/).last + "_ssim"
        attribute :thumbnail_id, Solr::String, "hasRelatedImage_ssim"
        attribute :thumbnail_path, Solr::String, CatalogController.blacklight_config.index.thumbnail_field
        attribute :label, Solr::String, "label_tesim"
        attribute :file_format, Solr::String, "file_format_tesim"
        attribute :suppressed?, Solr::String, "suppressed_bsi"
        attribute :original_file_id, Solr::String, "original_file_id_ssi"
        attribute :date_modified, Solr::Date, "date_modified_dtsi"
        attribute :date_uploaded, Solr::Date, "date_uploaded_dtsi"
        attribute :create_date, Solr::Date, "system_create_dtsi"
        attribute :modified_date, Solr::Date, "system_modified_dtsi"
        attribute :embargo_release_date, Solr::Date, Hydra.config.permissions.embargo.release_date
        attribute :lease_expiration_date, Solr::Date, Hydra.config.permissions.lease.expiration_date
      end
    end
  end
end
