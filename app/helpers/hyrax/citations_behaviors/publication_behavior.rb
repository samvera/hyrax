# frozen_string_literal: true
module Hyrax
  module CitationsBehaviors
    module PublicationBehavior
      include Hyrax::CitationsBehaviors::CommonBehavior
      def setup_pub_date(work)
        first_date = work.date_created.first if work.date_created
        if first_date.present?
          first_date = CGI.escapeHTML(first_date)
          date_value = first_date.gsub(/[^0-9|n\.d\.]/, "")[0, 4]
          return nil if date_value.nil?
        end
        clean_end_punctuation(date_value) if date_value
      end

      # @param [Hyrax::WorkShowPresenter] work_presenter
      def setup_pub_place(work_presenter)
        work_presenter.based_near_label&.first
      end

      def setup_pub_publisher(work)
        work.publisher&.first
      end

      def setup_pub_info(work, include_date = false)
        pub_info = [setup_pub_place(work), setup_pub_publisher(work)]
                   .filter_map { |pub| CGI.escapeHTML(pub) if pub.present? }
                   .join(': ')

        pub_date = include_date ? setup_pub_date(work) : nil
        [pub_info, pub_date].filter_map(&:presence).join(', ').strip.presence
      end
    end
  end
end
