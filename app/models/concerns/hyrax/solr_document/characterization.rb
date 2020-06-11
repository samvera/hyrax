# frozen_string_literal: true
module Hyrax
  module SolrDocument
    # TODO: aside from height and width, I don't think any of these other terms are indexed by default. - Justin 3/2016
    module Characterization
      def byte_order
        self["byte_order_tesim"]
      end

      def capture_device
        self["capture_device_tesim"]
      end

      def color_map
        self["color_map_tesim"]
      end

      def color_space
        self["color_space_tesim"]
      end

      def compression
        self["compression_tesim"]
      end

      def gps_timestamp
        self["gps_timestamp_tesim"]
      end

      def height
        self['height_is']
      end

      def image_producer
        self["image_producer_tesim"]
      end

      def latitude
        self["latitude_tesim"]
      end

      def longitude
        self["longitude_tesim"]
      end

      def orientation
        self["orientation_tesim"]
      end

      def profile_name
        self["profile_name_tesim"]
      end

      def profile_version
        self["profile_version_tesim"]
      end

      def scanning_software
        self["scanning_software_tesim"]
      end

      def width
        self['width_is']
      end

      def format_label
        self["format_label_tesim"]
      end

      def file_size
        self["file_size_tesim"]
      end

      def filename
        self["filename_tesim"]
      end

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
