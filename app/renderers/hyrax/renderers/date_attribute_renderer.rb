module Hyrax
  module Renderers
    class DateAttributeRenderer < AttributeRenderer
      private

        def attribute_value_to_html(value)
          Date.parse(value).to_formatted_s(:standard)
        end
    end
  end
end
