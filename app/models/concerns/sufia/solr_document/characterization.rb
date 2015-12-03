module Sufia
  module SolrDocument
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
        self[Solrizer.solr_name("height")]
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
        self[Solrizer.solr_name("width")]
      end
    end
  end
end
