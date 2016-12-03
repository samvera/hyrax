module Hyrax
  module SolrDocument
    # TODO: aside from height and width, I don't think any of these other terms are indexed by default. - Justin 3/2016
    module Characterization
      def byte_order
        self[Solrizer.solr_name("byte_order")]
      end

      def capture_device
        self[Solrizer.solr_name("capture_device")]
      end

      def color_map
        self[Solrizer.solr_name("color_map")]
      end

      def color_space
        self[Solrizer.solr_name("color_space")]
      end

      def compression
        self[Solrizer.solr_name("compression")]
      end

      def gps_timestamp
        self[Solrizer.solr_name("gps_timestamp")]
      end

      def height
        self['height_is']
      end

      def image_producer
        self[Solrizer.solr_name("image_producer")]
      end

      def latitude
        self[Solrizer.solr_name("latitude")]
      end

      def longitude
        self[Solrizer.solr_name("longitude")]
      end

      def orientation
        self[Solrizer.solr_name("orientation")]
      end

      def profile_name
        self[Solrizer.solr_name("profile_name")]
      end

      def profile_version
        self[Solrizer.solr_name("profile_version")]
      end

      def scanning_software
        self[Solrizer.solr_name("scanning_software")]
      end

      def width
        self['width_is']
      end

      def format_label
        self[Solrizer.solr_name("format_label")]
      end

      def file_size
        self[Solrizer.solr_name("file_size")]
      end

      def filename
        self[Solrizer.solr_name("filename")]
      end

      def well_formed
        self[Solrizer.solr_name("well_formed")]
      end

      def page_count
        self[Solrizer.solr_name("page_count")]
      end

      def file_title
        self[Solrizer.solr_name("file_title")]
      end

      def duration
        self[Solrizer.solr_name("duration")]
      end

      def sample_rate
        self[Solrizer.solr_name("sample_rate")]
      end

      def last_modified
        self[Solrizer.solr_name("last_modified")]
      end

      def original_checksum
        self[Solrizer.solr_name("original_checksum")]
      end
    end
  end
end
