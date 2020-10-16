# frozen_string_literal: true
module Hyrax
  module SolrDocument
    module Characterization
      ##
      # @todo this might not be indexed normally. deprecate?
      def byte_order
        self["byte_order_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def capture_device
        self["capture_device_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def color_map
        self["color_map_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def color_space
        self["color_space_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def compression
        self["compression_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def gps_timestamp
        self["gps_timestamp_tesim"]
      end

      def height
        self['height_is']
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def image_producer
        self["image_producer_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def latitude
        self["latitude_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def longitude
        self["longitude_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def orientation
        self["orientation_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def profile_name
        self["profile_name_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def profile_version
        self["profile_version_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def scanning_software
        self["scanning_software_tesim"]
      end

      def width
        self['width_is']
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def format_label
        self["format_label_tesim"]
      end

      def file_size
        self["file_size_lts"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def filename
        self["filename_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def well_formed
        self["well_formed_tesim"]
      end

      def page_count
        self["page_count_tesim"]
      end

      def file_title
        self["file_title_tesim"]
      end

      def duration
        self["duration_tesim"]
      end

      def sample_rate
        self["sample_rate_tesim"]
      end

      ##
      # @todo this might not be indexed normally. deprecate?
      def last_modified
        self["last_modified_tesim"]
      end

      def original_checksum
        self["original_checksum_tesim"]
      end

      def alpha_channels
        self["alpha_channels_ssi"]
      end
    end
  end
end
