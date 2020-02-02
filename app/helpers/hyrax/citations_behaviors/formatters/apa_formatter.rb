module Hyrax
  module CitationsBehaviors
    module Formatters
      class ApaFormatter < BaseFormatter
        include Hyrax::CitationsBehaviors::PublicationBehavior
        include Hyrax::CitationsBehaviors::TitleBehavior

        def format(work)
          text = ''
          text << authors_text_for(work)
          text << pub_date_text_for(work)
          text << add_title_text_for(work)
          text << add_publisher_text_for(work)
          text.html_safe
        end

        private

          def authors_text_for(work)
            # setup formatted author list
            authors_list = author_list(work).reject(&:blank?)
            author_text = format_authors(authors_list)
            if author_text.blank?
              author_text
            else
              "<span class=\"citation-author\">#{author_text}</span> "
            end
          end

        public

        def format_authors(authors_list = [])
          return '' if authors_list.blank?
          authors_list = Array.wrap(authors_list).collect { |name| abbreviate_name(surname_first(name)).strip }
          text = ''
          text << authors_list.first if authors_list.first
          authors_list[1..-1].each do |author|
            if author == authors_list.last # last
              text << ", &amp; " << author
            else # all others
              text << ", " << author
            end
          end
          text << "." unless text.end_with?(".")
          text
        end

        private

          def pub_date_text_for(work)
            # Get Pub Date
            pub_date = setup_pub_date(work)
            format_date(pub_date)
          end

          def add_title_text_for(work)
            # setup title info
            title_info = setup_title_info(work)
            format_title(title_info)
          end

          def add_publisher_text_for(work)
            # Publisher info
            pub_info = clean_end_punctuation(setup_pub_info(work))
            if pub_info.nil?
              ''
            else
              pub_info + "."
            end
          end

        public

        def format_date(pub_date)
          pub_date.blank? ? "" : "(" + pub_date + "). "
        end

        def format_title(title_info)
          title_info.nil? ? "" : "<i class=\"citation-title\">#{title_info}</i> "
        end
      end
    end
  end
end
