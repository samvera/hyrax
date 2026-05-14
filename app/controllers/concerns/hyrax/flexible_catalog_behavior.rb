# frozen_string_literal: true

module Hyrax
  module FlexibleCatalogBehavior
    extend ActiveSupport::Concern

    class_methods do
      def load_flexible_schema
        previous_profile, current_profile = Hyrax::FlexibleSchema.order("created_at asc").last(2).map(&:profile)
        return if previous_profile.blank? && current_profile.blank?

        current_profile = previous_profile if current_profile.nil?
        remove_old_properties!(previous_profile['properties'], current_profile['properties'].keys) if current_profile != previous_profile
        properties_hash = current_profile['properties']
        properties_hash.each do |itemprop, prop|
          label = display_label_for(itemprop, prop)

          view_options = prop['view']
          indexing = prop['indexing']
          next if indexing.nil?

          # prevents all restricted fields from being added to blacklight config
          # to prevent them from being exposed in catalog search results.
          # They remain available on show pages, based on visibility.
          if restricted_field?(indexing)
            remove_from_blacklight_config!(itemprop, indexing)
            next
          end

          if stored_searchable?(indexing, itemprop)
            index_args = { itemprop:, label: }

            if facetable?(indexing, itemprop)
              index_args[:link_to_facet] = "#{itemprop}_sim"
            end

            name = blacklight_config.index_fields.keys.detect { |key| key.start_with?(itemprop) }
            name ||= "#{itemprop}_tesim"

            # for properties that DO exist in the CatalogController
            if blacklight_config.index_fields[name].present?
              if label
                blacklight_config.index_fields[name].label = label
                blacklight_config.index_fields[name].custom_label = true
              end
              blacklight_config.index_fields[name].itemprop = itemprop

              blacklight_config.index_fields[name].link_to_facet = index_args[:link_to_facet]

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
              blacklight_config.add_facet_field(name, label: label)
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
        # Return a lambda so locale and translation are resolved at render time,
        # not at initialize time (before before_action :set_locale runs).
        lambda { |*|
          label = display_label[I18n.locale] || display_label[:default]
          I18n.t(label, default: label)
        }
      end

      def stored_searchable?(indexing, itemprop)
        indexing.include?('stored_searchable') || indexing.include?("#{itemprop}_tesim")
      end

      # True when the property declares `admin_only` or `editor_only` in its
      # indexing array. Restricted fields are never exposed through the
      # Blacklight catalog (no index column, no facet, no free-text match);
      # visibility is enforced on show pages by the `field_visible?` view
      # helper.
      def restricted_field?(indexing)
        indexing.include?("admin_only") || indexing.include?("editor_only")
      end

      def facetable?(indexing, itemprop)
        indexing.include?('facetable')
      end

      def remove_old_properties!(previous_profile_properties, current_property_keys)
        props = previous_profile_properties.keys - current_property_keys
        props.each do |prop|
          indexing = previous_profile_properties.dig(prop, 'indexing')
          remove_from_blacklight_config!(prop, indexing)
        end
      end

      # Evict every Blacklight registration for `itemprop`. Collects the set of
      # Solr field names to remove from three sources:
      # - "<itemprop>_tesim" — the default Solr field name used as the
      #   index field for this property,
      # - "<itemprop>_sim"   — the default Solr field name used as the
      #   facet field for this property,
      # - any additional Solr-field names explicitly declared in `indexing:`
      #   (filtering out the directive flags `stored_searchable`, `facetable`,
      #   `admin_only`, and `editor_only`).
      # Then removes those exact names from `facet_fields`, `index_fields`, and
      # the all_fields qf. Exact-name matching avoids prefix collisions where
      # e.g. `title` would otherwise match `title_alternative_*`.
      INDEXING_DIRECTIVES = %w[stored_searchable facetable admin_only editor_only].freeze

      def remove_from_blacklight_config!(itemprop, indexing = nil)
        names = solr_field_names_for(itemprop, indexing)
        names.each do |name|
          blacklight_config.facet_fields.delete(name)
          blacklight_config.index_fields.delete(name)
        end

        qf = blacklight_config.search_fields['all_fields']&.solr_parameters&.dig(:qf)
        return if qf.nil?
        names.each do |name|
          qf.slice!(" #{name}")
          qf.slice!(name)
        end
      end

      def solr_field_names_for(itemprop, indexing)
        default_fields = ["#{itemprop}_tesim", "#{itemprop}_sim"]
        declared_fields = (indexing || []) - INDEXING_DIRECTIVES
        (default_fields + declared_fields).uniq
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
