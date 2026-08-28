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
        resolvable = {}
        properties_hash.each do |itemprop, prop|
          label = display_label_for(itemprop, prop)

          view_options = prop['view']
          indexing = prop['indexing']
          next if indexing.nil?

          # A property may declare `name:` to stand in for another on a
          # particular class. The named attribute is what gets indexed, so it is
          # the name every solr field derives from — registering under the
          # surrogate's own key produces a facet nothing is indexed into.
          indexed_name = indexed_name_for(itemprop, prop)
          if indexed_name != itemprop
            # Only the surrogate's own keys. Passing its `indexing:` array would
            # fold in any field names it declares — which for a surrogate are
            # the target attribute's — and delete the target's registration.
            solr_field_names_for(itemprop, nil).each do |name|
              blacklight_config.facet_fields.delete(name)
              blacklight_config.index_fields.delete(name)
            end
            itemprop = indexed_name
          end

          # Only when the indexer will actually write label fields. `facetable`
          # and `stored_searchable` are directives that AttributeDefinition
          # strips, so a property declaring only those has no index keys and no
          # label companions — treating it as controlled would hide a working id
          # facet behind an empty label one.
          controlled_source = (controlled_source_for(prop, resolvable) if indexed?(indexing))

          # prevents all restricted fields from being added to blacklight config
          # to prevent them from being exposed in catalog search results.
          # They remain available on show pages, based on visibility.
          if restricted_field?(indexing)
            remove_from_blacklight_config!(itemprop, indexing)
            next
          end

          # `view.search_results: false` in the m3 profile hides this property from catalog
          # search-result columns. Only gates the dynamic add_index_field path below;
          # properties already declared in CatalogController are left untouched, and
          # the `qf` (query-field relevance) list is unaffected. Facet registration below
          # is intentionally not gated — a hidden property can still be facetable.
          if catalog_indexable?(view_options) && stored_searchable?(indexing, itemprop)
            index_args = { itemprop:, label: }

            if facetable?(indexing, itemprop)
              index_args[:link_to_facet] = facet_name_for(itemprop, controlled_source)
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

            # Carry an author-declared catalog truncation length onto the field
            # config (`view: { search_results_truncate: N }`, or `false` to opt out)
            # so render_html_index_value can honor it for render_as: html fields.
            if view_options.is_a?(Hash) && view_options.key?('search_results_truncate')
              blacklight_config.index_fields[name].search_results_truncate = view_options['search_results_truncate']
            end

            field = blacklight_config.index_fields[name]
            if controlled_source
              field.values = Hyrax::ControlledVocabularyFieldValues.to_proc
              field.reads_labels = true
            elsif field.reads_labels
              # Only one we set: an application's own `values:` has to stand.
              field.values = nil
              field.reads_labels = false
            end

            # The label field too, so a free-text search for a term's label
            # finds the work. Without it only the opaque id matches.
            names = [name]
            names << Hyrax::ControlledVocabularyFieldValues.label_key(name) if controlled_source
            append_query_fields!(names)
          end

          if facetable?(indexing, itemprop)
            register_facet_field(itemprop, label, controlled_source, indexing)
          else
            # if the property does not have facetable in the indexing section of the metadata profile, remove the facet field from the blacklight config
            blacklight_config.facet_fields.delete("#{itemprop}_sim")
            blacklight_config.facet_fields.delete("#{itemprop}_label_sim")
          end
        end
      end

      private

      # A controlled property facets on its labels, because Blacklight queries a
      # facet with whatever the row displayed — so row and facet move together.
      #
      # Runs once per request against a class-level config that persists, so
      # both the swap and the add have to be safe to repeat; Blacklight raises
      # when a facet is added twice.
      def register_facet_field(itemprop, label, controlled_source, indexing)
        id_name = "#{itemprop}_sim"
        id_facet = blacklight_config.facet_fields[id_name]
        id_facet = blacklight_config.add_facet_field(id_name, label: label) if id_facet.blank?

        # Restore a facet an earlier pass hid, for a property that has since
        # stopped being controlled. Only one we hid ourselves: a `show: false`
        # an application set in its own CatalogController has to stand.
        unless swap_facet_to_labels?(itemprop, controlled_source, indexing)
          id_facet.show = true if id_facet.hidden_for_labels
          id_facet.hidden_for_labels = false
          return
        end

        name = facet_name_for(itemprop, controlled_source)
        unless blacklight_config.facet_fields[name].present?
          # Resolved rather than copied: a facet declared in a CatalogController
          # without a label stores the titleized solr key ("Keyword Sim"), which
          # normally stays hidden only because display_label finds the
          # `…fields.facet.<key>` translation first — and the renamed key has no
          # such translation.
          blacklight_config.add_facet_field(name, label: id_facet.display_label('facet'))
        end

        # The id facet stays configured but drops out of the sidebar: listing
        # both would show the same label twice, one over the opaque ids this
        # feature exists to hide. Keeping it configured is what lets
        # `f[<prop>_sim][]` from a saved search or bookmark still resolve, and
        # keeps its constraint chip rendering.
        id_facet.show = false
        id_facet.hidden_for_labels = true
      end

      # The facet swap needs `<itemprop>_sim` specifically, not merely some
      # literal key: that is the field the indexer writes label companions for.
      # A property declaring only `<itemprop>_tesim` gets label values in rows
      # but none in a facet, so swapping would hide a working id facet behind an
      # empty label one.
      def swap_facet_to_labels?(itemprop, controlled_source, indexing)
        controlled_source.present? && Array(indexing).include?("#{itemprop}_sim")
      end

      def facet_name_for(itemprop, controlled_source)
        controlled_source ? "#{itemprop}_label_sim" : "#{itemprop}_sim"
      end

      # An installation with no label service registered gets nil for every
      # property, and so keeps the catalog it has today.
      def controlled_source_for(config, resolvable = {})
        return unless config.is_a?(Hash)

        # Not `config.dig`: a profile is editable data, and a scalar here would
        # raise TypeError while building the catalog config.
        controlled = config['controlled_values']
        return unless controlled.is_a?(Hash)

        Array(controlled['sources'])
          .map { |source| source.to_s.strip }
          .reject { |source| source.empty? || source.casecmp('null').zero? }
          .find { |source| resolvable?(source, resolvable) }
      rescue StandardError => e
        Hyrax.logger.debug("controlled_source_for: #{e.message}")
        nil
      end

      # Memoized for the duration of one load: this runs per property, and a
      # service backed by a vocabulary table would otherwise query once per
      # property per request.
      def resolvable?(source, memo)
        memo.fetch(source) do
          memo[source] = Hyrax.config.controlled_vocabulary_label_service.resolvable?(source)
        end
      end

      # Split on whitespace rather than substring-matching:
      # `qf.include?("type_tesim")` is true once `resource_type_tesim` is
      # listed, so a substring check would silently drop the shorter field.
      def append_query_fields!(names)
        qf = blacklight_config.search_fields['all_fields']&.solr_parameters&.dig(:qf)
        return if qf.nil?

        listed = qf.split
        names.each do |field|
          next if listed.include?(field)

          qf << " #{field}"
          listed << field
        end
      end

      # Whether `indexing:` names any literal solr field, as opposed to only the
      # directives (`stored_searchable`, `facetable`, the role flags) that carry
      # no field name of their own.
      def indexed?(indexing)
        (Array(indexing) - INDEXING_DIRECTIVES).any?
      end

      def indexed_name_for(itemprop, config)
        return itemprop unless config.is_a?(Hash)

        config['name'].presence || itemprop
      end

      # Returns true if the view options require a helper method to render the linked field correctly in the index view
      # @param view_options [Hash] the view options ex: {"render_as"=>"linked", "html_dl"=>true}
      # @return [Boolean] to determine if the view_option_for_helper_method should be called
      def require_view_helper_method?(view_options)
        view_options.present? && %w[external_link linked rights_statement html].include?(view_options.dig('render_as'))
      end

      # Returns the helper method that will render the linked field correctly in the index view
      # @param view_options [Hash] the view options ex: {"render_as"=>"linked", "html_dl"=>true}
      # @return [Symbol] helper method from Hyrax::HyraxHelperBehavior
      def view_option_for_helper_method(view_options)
        render_as = view_options.dig('render_as')
        return :iconify_auto_link if render_as == 'external_link'
        return :index_field_link if render_as == 'linked'
        return :rights_statement_links if render_as == 'rights_statement'
        return :render_html_index_value if render_as == 'html'
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

      # Returns false only when the m3 profile sets `view.search_results: false`
      # for the property; absent or `true` keeps existing catalog-display behavior.
      def catalog_indexable?(view_options)
        return true unless view_options.is_a?(Hash)
        view_options['search_results'] != false
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
        fields = (default_fields + declared_fields).uniq
        # blacklight_config is class-level and persists between requests, so a
        # property that leaves the profile or becomes restricted would otherwise
        # keep a live label facet pointing at a field nothing writes to.
        (fields + fields.map { |field| Hyrax::ControlledVocabularyFieldValues.label_key(field) }).uniq
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
