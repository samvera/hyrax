# frozen_string_literal: true

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
          text = text.dup << format_authors(authors_list)
          if text.present?
            text = "<span class=\"citation-author\">#{text}</span>"
          end
          # Get Pub Date
          pub_date = setup_pub_date(work)
          text = text.dup << " #{pub_date}." unless pub_date.nil?
          text = text.dup << "." unless text.blank? || text =~ /\.$/

          text = text.dup << format_title(work.to_s)
          pub_info = setup_pub_info(work, false)
          text = text.dup << " #{pub_info}." if pub_info.present?
          text.html_safe
        end

        def format_authors(authors_list = [])
          return '' if authors_list.blank?
          text = ''
          text = text.dup << surname_first(authors_list.first) if authors_list.first
          authors_list[1..6].each_with_index do |author, index|
            # we've skipped the first author
            text = text.dup << (index + 2 == authors_list.length ? ', and ' : ', ') << "#{given_name_first(author)}."
          end
          text = text.dup << " et al." if authors_list.length > 7
          # if for some reason the first author ended with a comma
          text.gsub!(',,', ',')
          text = text.dup << "." unless text.match?(/\.$/)
          text
        end

        def format_date(pub_date); end

        def format_title(title_info)
          return "" if title_info.blank?
          title_text = chicago_citation_title(title_info)
          title_text = title_text.dup << '.' unless title_text.match?(/\.$/)
          " <i class=\"citation-title\">#{title_text}</i>"
        end
      end
    end
  end
end
