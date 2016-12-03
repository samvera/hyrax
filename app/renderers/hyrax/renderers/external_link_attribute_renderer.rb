module Hyrax
  module Renderers
    class ExternalLinkAttributeRenderer < AttributeRenderer
      private

        def li_value(value)
          auto_link(value) do |link|
            "<span class='glyphicon glyphicon-new-window'></span>&nbsp;#{link}"
          end
        end
    end
  end
end
