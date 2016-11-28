module Sufia
  module Renderers
    module ConfiguredMicrodata
      PREFIX = 'sufia.schema_org'.freeze

      def microdata?(field)
        return false unless Sufia.config.display_microdata
        key = "#{PREFIX}.#{field}.property"
        t(key, default: false)
      end

      def microdata_object?(field)
        return false unless Sufia.config.display_microdata
        key = "#{PREFIX}.#{field}.type"
        t(key, default: false)
      end

      def microdata_object_attributes(field)
        if microdata_object?(field)
          { itemprop: microdata_property(field), itemscope: '', itemtype: microdata_type(field) }
        else
          {}
        end
      end

      def microdata_property(field)
        t("#{PREFIX}.#{field}.property")
      end

      def microdata_type(field)
        t("#{PREFIX}.#{field}.type")
      end

      def microdata_value_attributes(field)
        if microdata?(field)
          key = microdata_object?(field) ? :value : :property
          { itemprop: t("#{PREFIX}.#{field}.#{key}") }
        else
          {}
        end
      end
    end
  end
end
