module CurationConcerns
  module Renderers
    module ConfiguredMicrodata
      def microdata?(field)
        return false unless CurationConcerns.config.display_microdata
        key = "curation_concerns.schema_org.#{field}.property"
        t(key, default: false)
      end

      def microdata_object?(field)
        return false unless CurationConcerns.config.display_microdata
        key = "curation_concerns.schema_org.#{field}.type"
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
        t("curation_concerns.schema_org.#{field}.property")
      end

      def microdata_type(field)
        t("curation_concerns.schema_org.#{field}.type")
      end

      def microdata_value_attributes(field)
        if microdata?(field)
          key = microdata_object?(field) ? :value : :property
          { itemprop: t("curation_concerns.schema_org.#{field}.#{key}") }
        else
          {}
        end
      end
    end
  end
end
