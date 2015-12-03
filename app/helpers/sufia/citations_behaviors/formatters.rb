module Sufia
  module CitationsBehaviors
    module Formatters
      class BaseFormatter
        include Sufia::CitationsBehaviors::CommonBehavior
        include Sufia::CitationsBehaviors::NameBehavior

        def process_title_parts(title_text, &block)
          if block_given?
            title_text.split(" ").collect.with_index(&block).join(" ")
          else
            title_text
          end
        end
      end

      autoload :ApaFormatter, 'sufia/citations_behaviors/formatters/apa_formatter'
      autoload :ChicagoFormatter, 'sufia/citations_behaviors/formatters/chicago_formatter'
      autoload :EndnoteFormatter, 'sufia/citations_behaviors/formatters/endnote_formatter'
      autoload :MlaFormatter, 'sufia/citations_behaviors/formatters/mla_formatter'
      autoload :OpenUrlFormatter, 'sufia/citations_behaviors/formatters/open_url_formatter'
    end
  end
end
