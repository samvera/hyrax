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

          view_options = prop['view']
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

            # for properties that DO exist in the CatalogController
            if blacklight_config.index_fields[name].present?
              if label
                blacklight_config.index_fields[name].label = I18n.t(label, default: label)
                blacklight_config.index_fields[name].custom_label = true
              end
              blacklight_config.index_fields[name].itemprop = itemprop

              if require_view_helper_method?(view_options)
                # add or update the helper method so linked fields will render correctly in the index view
                blacklight_config.index_fields[name].helper_method = view_option_for_helper_method(view_options)
                # the helper method for index_field_link needs the field name
                blacklight_config.index_fields[name].field_name = itemprop
              end
            else
              # for properties that DO NOT exist in the catalog controller
              if require_view_helper_method?(view_options)
                # add the view helper method to the arguments hash when creating a property
                index_args[:helper_method] = view_option_for_helper_method(view_options)
                # the helper method for index_field_link needs the field name
                index_args[:field_name] = itemprop
              end
              # if a property in the metadata profile doesn't exist in the CatalogController, add it
              blacklight_config.add_index_field(name, index_args)

              # all index fields get this property so an admin can hide a property from the catalog search results
              # by adding the name of the property via admin dashboard > Settings > Accounts > Hidden index fields
              # NOTE: it is likely this will be handled by the metadata profile in the future
              blacklight_config.index_fields[name].if = :render_optionally?
            end

            qf = blacklight_config.search_fields['all_fields'].solr_parameters[:qf]
            unless qf.include?(name)
              qf << " #{name}"
            end
          end

          if facetable?(indexing, itemprop)
            name = "#{itemprop}_sim"
            unless blacklight_config.facet_fields[name].present?
              facet_args = { label: }
              if indexing.include?("admin_only")
                facet_args[:if] = lambda { |context, _field_config, _document| context.try(:current_user)&.admin? }
              end
              blacklight_config.add_facet_field(name, **facet_args)
            end
          else
            # if the property does not have facetable in the indexing section of the metadata profile, remove the facet field from the blacklight config
            name = "#{itemprop}_sim"
            blacklight_config.facet_fields.delete(name)
          end
        end
      end

      private

      # Returns true if the view options require a helper method to render the linked field correctly in the index view
      # @param view_options [Hash] the view options ex: {"render_as"=>"linked", "html_dl"=>true}
      # @return [Boolean] to determine if the view_option_for_helper_method should be called
      def require_view_helper_method?(view_options)
        view_options.present? && %w[external_link linked rights_statement].include?(view_options.dig('render_as'))
      end

      # Returns the helper method that will render the linked field correctly in the index view
      # @param view_options [Hash] the view options ex: {"render_as"=>"linked", "html_dl"=>true}
      # @return [Symbol] helper method from Hyrax::HyraxHelperBehavior
      def view_option_for_helper_method(view_options)
        render_as = view_options.dig('render_as')
        return :iconify_auto_link if render_as == 'external_link'
        return :index_field_link if render_as == 'linked'
        return :rights_statement_links if render_as == 'rights_statement'
      end

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

    # Hook to allow optional rendering at the app level
    def render_optionally?
      true
    end
  end
end
