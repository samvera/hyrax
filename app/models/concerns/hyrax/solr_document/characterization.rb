module Hyrax
  module SolrDocument
    # TODO: aside from height and width, I don't think any of these other terms are indexed by default. - Justin 3/2016
    module Characterization
      def byte_order
        self[Hyrax.config.index_field_mapper.solr_name("byte_order")]
      end

      def capture_device
        self[Hyrax.config.index_field_mapper.solr_name("capture_device")]
      end

      def color_map
        self[Hyrax.config.index_field_mapper.solr_name("color_map")]
      end

      def color_space
        self[Hyrax.config.index_field_mapper.solr_name("color_space")]
      end

      def compression
        self[Hyrax.config.index_field_mapper.solr_name("compression")]
      end

      def gps_timestamp
        self[Hyrax.config.index_field_mapper.solr_name("gps_timestamp")]
      end

      def height
        self['height_is']
      end

      def image_producer
        self[Hyrax.config.index_field_mapper.solr_name("image_producer")]
      end

      def latitude
        self[Hyrax.config.index_field_mapper.solr_name("latitude")]
      end

      def longitude
        self[Hyrax.config.index_field_mapper.solr_name("longitude")]
      end

      def orientation
        self[Hyrax.config.index_field_mapper.solr_name("orientation")]
      end

      def profile_name
        self[Hyrax.config.index_field_mapper.solr_name("profile_name")]
      end

      def profile_version
        self[Hyrax.config.index_field_mapper.solr_name("profile_version")]
      end

      def scanning_software
        self[Hyrax.config.index_field_mapper.solr_name("scanning_software")]
      end

      def width
        self['width_is']
      end

      def format_label
        self[Hyrax.config.index_field_mapper.solr_name("format_label")]
      end

      def file_size
        self[Hyrax.config.index_field_mapper.solr_name("file_size")]
      end

      def filename
        self[Hyrax.config.index_field_mapper.solr_name("filename")]
      end

      def well_formed
        self[Hyrax.config.index_field_mapper.solr_name("well_formed")]
      end

      def page_count
        self[Hyrax.config.index_field_mapper.solr_name("page_count")]
      end

      def file_title
        self[Hyrax.config.index_field_mapper.solr_name("file_title")]
      end

      def duration
        self[Hyrax.config.index_field_mapper.solr_name("duration")]
      end

      def sample_rate
        self[Hyrax.config.index_field_mapper.solr_name("sample_rate")]
      end

      def last_modified
        self[Hyrax.config.index_field_mapper.solr_name("last_modified")]
      end

      def original_checksum
        self[Hyrax.config.index_field_mapper.solr_name("original_checksum")]
      end

      def alpha_channels
        self[ActiveFedora.index_field_mapper.solr_name("alpha_channels")]
      end
    end
  end
end
