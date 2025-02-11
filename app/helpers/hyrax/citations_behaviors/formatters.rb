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
    end
  end
end
