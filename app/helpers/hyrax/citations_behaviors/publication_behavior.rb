module Hyrax
  module CitationsBehaviors
    module PublicationBehavior
      include Hyrax::CitationsBehaviors::CommonBehavior
      def setup_pub_date(work)
        first_date = work.date_created.first if work.date_created
        unless first_date.blank?
          first_date = CGI.escapeHTML(first_date)
          date_value = first_date.gsub(/[^0-9|n\.d\.]/, "")[0, 4]
          return nil if date_value.nil?
        end
        clean_end_punctuation(date_value) if date_value
      end

      def setup_pub_place(work)
        work.based_near.first if work.based_near
      end

      def setup_pub_publisher(work)
        work.publisher.first if work.publisher
      end

      def setup_pub_info(work, include_date = false)
        pub_info = ""
        if (place = setup_pub_place(work))
          pub_info << CGI.escapeHTML(place)
        end
        if (publisher = setup_pub_publisher(work))
          pub_info << ": " << CGI.escapeHTML(publisher)
        end

        pub_date = include_date ? setup_pub_date(work) : nil
        pub_info << ", " << pub_date unless pub_date.nil?

        pub_info.strip!
        pub_info.blank? ? nil : pub_info
      end
    end
  end
end
