##
# frozen_string_literal: true
module Hyrax
  module Forms
    ##
    # @api public
    # @see https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking
    class PcdmCollectionForm < Valkyrie::ChangeSet # rubocop:disable Metrics/ClassLength
      include Hyrax::FormFields(:core_metadata)
      include Hyrax::FormFields(:basic_metadata)
      # include Hyrax::FormFields(:collection)

      property :human_readable_type, writable: false
      # property :visibility, default: VisibilityIntention::PRIVATE
      property :date_modified, readable: false
      property :date_uploaded, readable: false

      # property :title, required: true
      property :depositor, required: true
      property :collection_type_gid, required: true

      collection(:permissions,
                 virtual: true,
                 default: [],
                 form: Hyrax::Forms::Permission,
                 populator: :permission_populator,
                 prepopulator: ->(_opts) { self.permissions = Hyrax::AccessControl.for(resource: model).permissions })

      # pcdm relationships
      property :member_ids, default: [], type: Valkyrie::Types::Array
      property :member_of_collection_ids, default: [], type: Valkyrie::Types::Array

      class << self
        def model_class
          Hyrax::PcdmCollection
        end

        ##
        # @return [Array<Symbol>] list of required field names as symbols
        def required_fields
          definitions
            .select { |_, definition| definition[:required] }
            .keys.map(&:to_sym)
        end

        def membership_service_class
          Collections::CollectionMemberSearchService
        end
      end

      ##
      # @return [Array<Symbol>] terms for display 'above-the-fold', or in the most
      #   prominent form real estate
      def primary_terms
        _form_field_definitions
          .select { |_, definition| definition[:primary] }
          .keys.map(&:to_sym)
      end

      ##
      # @return [Array<Symbol>] terms for display 'below-the-fold'
      def secondary_terms
        _form_field_definitions
          .select { |_, definition| definition[:display] && !definition[:primary] }
          .keys.map(&:to_sym)
      end

      ##
      # @return [Boolean] whether there are terms to display 'below-the-fold'
      def display_additional_fields?
        secondary_terms.any?
      end

      def banner_info
        @banner_info ||= begin
                           # Find Banner filename
                           banner_info = CollectionBrandingInfo.where(collection_id: id, role: "banner")
                           banner_file = File.split(banner_info.first.local_path).last unless banner_info.empty?
                           alttext = banner_info.first.alt_text unless banner_info.empty?
                           file_location = banner_info.first.local_path unless banner_info.empty?
                           relative_path = "/" + banner_info.first.local_path.split("/")[-4..-1].join("/") unless banner_info.empty?
                           { file: banner_file, full_path: file_location, relative_path: relative_path, alttext: alttext }
                         end
      end

      def logo_info
        @logo_info ||= begin
                         # Find Logo filename, alttext, linktext
                         logos_info = CollectionBrandingInfo.where(collection_id: id, role: "logo")

                         logos_info.map do |logo_info|
                           logo_file = File.split(logo_info.local_path).last
                           relative_path = "/" + logo_info.local_path.split("/")[-4..-1].join("/")
                           alttext = logo_info.alt_text
                           linkurl = logo_info.target_url
                           { file: logo_file, full_path: logo_info.local_path, relative_path: relative_path, alttext: alttext, linkurl: linkurl }
                         end
                       end
      end

      def list_parent_collections
        collection.member_of_collections
      end

      def list_child_collections
        collection_member_service.available_member_subcollections.documents
      end

      ##
      # @deprecated this implementation requires an extra db round trip, had a
      #   buggy cacheing mechanism, and was largely duplicative of other code.
      #   all versions of this code are replaced by
      #   {CollectionsHelper#available_parent_collections_data}.
      def available_parent_collections(scope:)
        return @available_parents if @available_parents.present?

        collection = ::Collection.find(id)
        colls = Hyrax::Collections::NestedCollectionQueryService.available_parent_collections(child: collection, scope: scope, limit_to_id: nil)
        @available_parents = colls.map do |col|
          { "id" => col.id, "title_first" => col.title.first }
        end.to_json
      end

      private

      def _form_field_definitions
        self.class.definitions
      end

      def all_files_with_access
        member_presenters(member_work_ids).flat_map(&:file_set_presenters).map { |x| [x.to_s, x.id] }
      end

      # Override this method if you have a different way of getting the member's ids
      def member_work_ids
        response = collection_member_service.available_member_work_ids.response
        response.fetch('docs').map { |doc| doc['id'] }
      end

      def collection_member_service
        @collection_member_service ||= membership_service_class.new(scope: scope, collection: collection, params: blacklight_config.default_solr_params)
      end

      def member_presenters(member_ids)
        PresenterFactory.build_for(ids: member_ids,
                                   presenter_class: WorkShowPresenter,
                                   presenter_args: [nil])
      end
    end
  end
end
