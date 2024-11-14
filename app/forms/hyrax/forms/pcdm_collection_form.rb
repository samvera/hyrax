# frozen_string_literal: true

module Hyrax
  module Forms
    ##
    # @api public
    # @see https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking
    class PcdmCollectionForm < Hyrax::Forms::ResourceForm # rubocop:disable Metrics/ClassLength
      include Hyrax::FormFields(:core_metadata)

      BannerInfoPrepopulator = lambda do |**_options|
        self.banner_info ||= begin
          banner_info = CollectionBrandingInfo.where(collection_id: id.to_s, role: "banner")
          banner_file = File.split(banner_info.first.local_path).last unless banner_info.empty?
          alttext = banner_info.first.alt_text unless banner_info.empty?
          file_location = banner_info.first.local_path unless banner_info.empty?
          relative_path = "/" + banner_info.first.local_path.split("/")[-4..-1].join("/") unless banner_info.empty?
          { file: banner_file, full_path: file_location, relative_path: relative_path, alttext: alttext }
        end
      end

      LogoInfoPrepopulator = lambda do |**_options|
        self.logo_info ||= begin
          logos_info = CollectionBrandingInfo.where(collection_id: id.to_s, role: "logo")

          logos_info.map do |logo_info|
            logo_file = File.split(logo_info.local_path).last
            relative_path = "/" + logo_info.local_path.split("/")[-4..-1].join("/")
            alttext = logo_info.alt_text
            linkurl = logo_info.target_url
            { file: logo_file, full_path: logo_info.local_path, relative_path: relative_path, alttext: alttext, linkurl: linkurl }
          end
        end
      end

      property :depositor, required: true
      property :collection_type_gid, required: true
      property :visibility, default: VisibilityIntention::PRIVATE

      property :member_of_collection_ids, default: [], type: Valkyrie::Types::Array

      validates :collection_type_gid, presence: true

      property :banner_info, virtual: true, prepopulator: BannerInfoPrepopulator
      property :logo_info, virtual: true, prepopulator: LogoInfoPrepopulator

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

      ##
      # This feature is not supported in Valkyrie collections and should be removed as part of #5764
      # However, the depreciated method is still needed for some specs
      # @return [] always empty.
      def select_files
        Deprecation.warn "`Hyrax::PcdmCollection` does not currently support thumbnail_id. Collection thumbnails need to be redesigned as part of issue #5764"
        []
      end

      private

      def _form_field_definitions
        self.class.definitions
      end
    end
  end
end
