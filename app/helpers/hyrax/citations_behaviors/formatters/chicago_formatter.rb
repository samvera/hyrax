module Hyrax
  module CitationsBehaviors
    module Formatters
      class ChicagoFormatter < BaseFormatter
        include Hyrax::CitationsBehaviors::PublicationBehavior
        include Hyrax::CitationsBehaviors::TitleBehavior

        def format(work)
          text = ""

          # setup formatted author list
          authors_list = all_authors(work)
          text << format_authors(authors_list)
          unless text.blank?
            text = "<span class=\"citation-author\">#{text}</span>"
          end
          # Get Pub Date
          pub_date = setup_pub_date(work)
          text << " #{pub_date}." unless pub_date.nil?
          text << "." unless text.blank? || text =~ /\.$/

          text << format_title(work.to_s)
          pub_info = setup_pub_info(work, false)
          text << " #{pub_info}." unless pub_info.blank?
          text.html_safe
        end

        def format_authors(authors_list = [])
          unless authors_list.blank?
            text = ''
            text << surname_first(authors_list.first) if authors_list.first
            authors_list[1..6].each_with_index do |author, index|
              text << if index + 2 == authors_list.length # we've skipped the first author
                        ", and #{given_name_first(author)}."
                      else
                        ", #{given_name_first(author)}"
                      end
            end
            text << " et al." if authors_list.length > 7
          end
          # if for some reason the first author ended with a comma
          text.gsub!(',,', ',')
          text << "." unless text =~ /\.$/
          text
        end

        def format_date(pub_date); end

        def format_title(title_info)
          return "" if title_info.blank?
          title_text = chicago_citation_title(title_info)
          title_text << '.' unless title_text =~ /\.$/
          " <i class=\"citation-title\">#{title_text}</i>"
        end
      end
    end
  end
end
