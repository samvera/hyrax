module Sufia
  module CitationsBehaviors
    module Formatters
      class BaseFormatter
        include Sufia::CitationsBehaviors::CommonBehavior
        include Sufia::CitationsBehaviors::NameBehavior

        attr_reader :view_context

        def initialize(view_context)
          @view_context = view_context
        end
      end

      autoload :ApaFormatter, 'sufia/citations_behaviors/formatters/apa_formatter'
      autoload :ChicagoFormatter, 'sufia/citations_behaviors/formatters/chicago_formatter'
      autoload :MlaFormatter, 'sufia/citations_behaviors/formatters/mla_formatter'
      autoload :OpenUrlFormatter, 'sufia/citations_behaviors/formatters/open_url_formatter'
    end
  end
end
