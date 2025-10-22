# frozen_string_literal: true

module Hyrax
  module FlexibleCatalogBehavior
    extend ActiveSupport::Concern

    class_methods do
      def load_flexible_schema
        previous_profile, current_profile = Hyrax::FlexibleSchema.order("created_at asc").last(2).map(&:profile)
        return if previous_profile.blank? && current_profile.blank?

        current_profile = previous_profile if current_profile.nil?
        remove_old_properties!(previous_profile['properties'].keys, current_profile['properties'].keys) if current_profile != previous_profile
        properties_hash = current_profile['properties']
        properties_hash.each do |itemprop, prop|
          label = display_label_for(itemprop, prop)
          indexing = prop['indexing']
          next if indexing.nil?

          if stored_searchable?(indexing, itemprop)
            index_args = { itemprop:, label: }

            if admin_only?(indexing)
              index_args[:if] = lambda { |context, _field_config, _document| context.try(:current_user)&.admin? }
            end

            if facetable?(indexing, itemprop)
              index_args[:link_to_facet] = "#{itemprop}_sim"
            end

            name = blacklight_config.index_fields.keys.detect { |key| key.start_with?(itemprop) }
            name ||= "#{itemprop}_tesim"

            if blacklight_config.index_fields[name].present?
              if label
                blacklight_config.index_fields[name].label = t(label, default: label)
                blacklight_config.index_fields[name].custom_label = true
              end
              blacklight_config.index_fields[name].itemprop = itemprop
            else
              blacklight_config.add_index_field(name, index_args)
            end

            qf = blacklight_config.search_fields['all_fields'].solr_parameters[:qf]
            unless qf.include?(name)
              qf << " #{name}"
            end
          end

          if facetable?(indexing, itemprop)
            name = "#{itemprop}_sim"
            facet_args = { label: }
            if indexing.include?("admin_only")
              facet_args[:if] = lambda { |context, _field_config, _document| context.try(:current_user)&.admin? }
            end

            unless blacklight_config.facet_fields[name].present?
              blacklight_config.add_facet_field(name, **facet_args)
            end
          end
        end
      end

      private

      def display_label_for(field_name, config)
        display_label = config.fetch('display_label', {})&.with_indifferent_access || {}
        display_label = { default: display_label } if display_label.is_a?(String)
        display_label[:default] = field_name.to_s.humanize if display_label[:default].blank?
        display_label[I18n.locale] || display_label[:default]
      end

      def stored_searchable?(indexing, itemprop)
        indexing.include?('stored_searchable') || indexing.include?("#{itemprop}_tesim")
      end

      def admin_only?(indexing)
        indexing.include?("admin_only")
      end

      def facetable?(indexing, itemprop)
        indexing.include?('facetable')
      end

      def remove_old_properties!(previous_properties, current_properties)
        props = previous_properties - current_properties
        return if props.empty?

        props.each do |prop|
          # remove from facet field
          blacklight_config.facet_fields.delete("#{prop}_sim")
          # remove from index field
          blacklight_config.facet_fields.delete("#{prop}_tesim")
          # remove from qf
          blacklight_config.search_fields['all_fields'].solr_parameters[:qf].slice!("#{prop}_tesim")
        end
      end
    end

    def initialize
      self.class.load_flexible_schema
      super
    end
  end
end
