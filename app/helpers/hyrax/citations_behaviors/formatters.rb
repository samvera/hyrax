# frozen_string_literal: true
module Hyrax
  module CitationsBehaviors
    module Formatters
      class BaseFormatter
        include Hyrax::CitationsBehaviors::CommonBehavior
        include Hyrax::CitationsBehaviors::NameBehavior

        attr_reader :view_context

        def initialize(view_context)
          @view_context = view_context
        end
      end

      autoload :ApaFormatter, 'hyrax/citations_behaviors/formatters/apa_formatter'
      autoload :ChicagoFormatter, 'hyrax/citations_behaviors/formatters/chicago_formatter'
      autoload :MlaFormatter, 'hyrax/citations_behaviors/formatters/mla_formatter'
      autoload :OpenUrlFormatter, 'hyrax/citations_behaviors/formatters/open_url_formatter'
    end
  end
end
