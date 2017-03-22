module Hyrax
  module Renderers
    module ConfiguredMicrodata
      def microdata?(field)
        return false unless Hyrax.config.display_microdata?
        translate_microdata(field: field, field_context: 'property', default: false)
      end

      def microdata_object?(field)
        return false unless Hyrax.config.display_microdata?
        translate_microdata(field: field, field_context: 'type', default: false)
      end

      def microdata_object_attributes(field)
        if microdata_object?(field)
          { itemprop: microdata_property(field), itemscope: '', itemtype: microdata_type(field) }
        else
          {}
        end
      end

      def microdata_property(field)
        translate_microdata(field: field, field_context: 'property')
      end

      def microdata_type(field)
        translate_microdata(field: field, field_context: 'type')
      end

      def microdata_value_attributes(field)
        if microdata?(field)
          field_context = microdata_object?(field) ? :value : :property
          { itemprop: translate_microdata(field: field, field_context: field_context) }
        else
          {}
        end
      end

      private

        def translate_microdata(field:, field_context:, default: true)
          Microdata.fetch("#{field}.#{field_context}", default: default)
        end
    end
  end
end
