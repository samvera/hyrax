module Hyrax
  module CitationsBehaviors
    module Formatters
      class ApaFormatter < BaseFormatter
        include Hyrax::CitationsBehaviors::PublicationBehavior
        include Hyrax::CitationsBehaviors::TitleBehavior

        def format(work)
          text = ''

          # setup formatted author list
          authors_list = author_list(work).select { |author| !author.blank? }
          text << format_authors(authors_list)
          unless text.blank?
            text = "<span class=\"citation-author\">#{text}</span> "
          end
          # Get Pub Date
          pub_date = setup_pub_date(work)
          text << format_date(pub_date)

          # setup title info
          title_info = setup_title_info(work)
          text << format_title(title_info)

          # Publisher info
          pub_info = clean_end_punctuation(setup_pub_info(work))
          text << pub_info unless pub_info.nil?
          text << "." unless text.blank? || text =~ /\.$/
          text.html_safe
        end

        def format_authors(authors_list = [])
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
          text << "." unless text =~ /\.$/
          text
        end

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
