module Hyrax
  module CitationsBehaviors
    module Formatters
      class MlaFormatter < BaseFormatter
        include Hyrax::CitationsBehaviors::PublicationBehavior
        include Hyrax::CitationsBehaviors::TitleBehavior

        def format(work)
          text = ''

          # setup formatted author list
          authors = author_list(work).select { |author| !author.blank? }
          text << "<span class=\"citation-author\">#{format_authors(authors)}</span>"
          # setup title
          title_info = setup_title_info(work)
          text << format_title(title_info)

          # Publication
          pub_info = clean_end_punctuation(setup_pub_info(work, true))

          text << pub_info unless pub_info.blank?
          text << "." unless text.blank? || text =~ /\.$/
          text.html_safe
        end

        def format_authors(authors_list = [])
          return "" if authors_list.blank?
          authors_list = Array.wrap(authors_list)
          text = concatenate_authors_from(authors_list)
          unless text.blank?
            text << "." unless text =~ /\.$/
            text << " "
          end
          text
        end

        def concatenate_authors_from(authors_list)
          text = ''
          text << surname_first(authors_list.first)
          if authors_list.length > 1
            if authors_list.length < 4
              authors_list[1...-1].each do |author|
                text << ", " << given_name_first(author)
              end
              text << ", and #{given_name_first(authors_list.last)}"
            else
              text << ", et al"
            end
          end
          text
        end
        private :concatenate_authors_from

        def format_date(pub_date)
          pub_date
        end

        def format_title(title_info)
          title_info.blank? ? "" : "<i class=\"citation-title\">#{mla_citation_title(title_info)}</i> "
        end
      end
    end
  end
end
