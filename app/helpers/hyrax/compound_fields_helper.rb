# frozen_string_literal: true

module Hyrax
  # View helpers for rendering compound (hierarchical) metadata fields on forms
  # and show pages. See documentation/compound_fields.md.
  module CompoundFieldsHelper
    ##
    # Renders one compound section (a repeatable stack of sub-property rows) for the
    # given attribute via the `hyrax/compounds/*` partials.
    #
    # @return [String, nil] rendered HTML, or nil when the attribute is not a
    #   declared compound on the model.
    def render_compound_field(f, compound_name)
      schema = Hyrax::CompoundSchema.for(f.object.model)
      definition = schema.definition_for(compound_name)
      return nil if definition.nil?

      render 'hyrax/compounds/compound_section',
             f: f,
             compound_name: compound_name.to_sym,
             definition: definition,
             display_label: compound_field_label(compound_name, display_label: definition[:display_label])
    end

    ##
    # @return [Boolean] whether the field is a card-display compound
    #   (`view: { display: card }`). Show views use this to skip card compounds
    #   in the inline metadata list.
    def compound_card_field?(presenter, field)
      compound_schema_for(presenter).card?(field)
    rescue StandardError
      false
    end

    ##
    # Render every card-display compound that has a value as its own titled card
    # (matching the relationships/items cards).
    #
    # @param [Object] presenter a work or collection show presenter
    # @return [ActiveSupport::SafeBuffer]
    def render_compound_cards(presenter)
      safe_join(compound_schema_for(presenter).card_compound_names.map do |name|
        next ''.html_safe unless presenter.respond_to?(name) && presenter.public_send(name).present?

        render 'hyrax/compounds/compound_card', presenter: presenter, field: name
      end)
    rescue StandardError => e
      Hyrax.logger.debug("render_compound_cards: #{e.message}")
      ''.html_safe
    end

    # The compound schema for a show presenter, resolved from the backing Solr
    # document so it works in flexible mode (where the class carries no
    # compounds). Memoized per request. See {Hyrax::CompoundSchema.for_solr_document}.
    def compound_schema_for(presenter)
      @compound_schemas ||= {}
      @compound_schemas[presenter.object_id] ||=
        if presenter.respond_to?(:solr_document) && presenter.solr_document.respond_to?(:hydra_model)
          Hyrax::CompoundSchema.for_solr_document(presenter.solr_document)
        elsif presenter.is_a?(Hyrax::CollectionPresenter)
          Hyrax::CompoundSchema.for(Hyrax.config.collection_class)
        else
          Hyrax::CompoundSchema.new
        end
    end

    ##
    # Options for a `controlled` sub-property's `<select>`: an inline `values:`
    # list when present, otherwise the named QA authority. A stored value not
    # among the options is appended so it still renders (`include_current_value`).
    #
    # @return [Array<Array(String, String)>] `[[label, id], ...]`
    def compound_subproperty_options(spec, current_value = nil)
      options = spec[:values].presence || authority_options(spec[:authority])
      ensure_current_value(options, current_value)
    end

    ##
    # @return [Boolean] whether +current_value+ is present but not among the
    #   sub-property's offered options — i.e. a forced/stale value. The select
    #   gets the +force-select+ class in that case, matching the ordinary
    #   controlled-field convention.
    def compound_subproperty_forced?(spec, current_value = nil)
      return false if current_value.blank?
      base = spec[:values].presence || authority_options(spec[:authority])
      base.none? { |(_label, id)| id.to_s == current_value.to_s }
    end

    ##
    # The pre-selected `[label, value]` option for a `work_or_url` sub-property's
    # select2, or nil when empty. An internal work id resolves to its title; an
    # external URL is shown as-is.
    #
    # @return [Array(String, String), nil]
    def compound_work_or_url_option(value)
      return nil if value.blank?
      return [value.to_s, value.to_s] if Hyrax::CompoundWorkResolver.url?(value)

      title, = Hyrax::CompoundWorkResolver.title_and_path(value)
      [title, value.to_s]
    end

    # The label for a compound. A declared `display_label` is resolved through
    # the same path ordinary properties use ({Hyrax::AttributesHelper#conform_options});
    # otherwise it falls back to the `hyrax.compound_fields.<name>.label` key.
    #
    # @param display_label [Hash, nil] the compound's `{ locale => label }` hash
    def compound_field_label(compound_name, display_label: nil)
      if display_label.present?
        conform_options(compound_name.to_s, display_label: display_label)[:label]
      else
        t("hyrax.compound_fields.#{compound_name}.label", default: compound_name.to_s.humanize)
      end
    rescue StandardError
      t("hyrax.compound_fields.#{compound_name}.label", default: compound_name.to_s.humanize)
    end

    # The card title for a compound on a show page (resolves the compound's
    # declared display_label from the presenter's schema).
    def compound_card_label(presenter, field)
      compound_field_label(field, display_label: compound_schema_for(presenter).definition_for(field)&.dig(:display_label))
    end

    def compound_subproperty_label(compound_name, sub_property)
      t("hyrax.compound_fields.#{compound_name}.#{sub_property}",
        default: sub_property.to_s.humanize)
    end

    ##
    # Renders a small linked ORCID iD badge. The href targets
    # `https://orcid.org/<id>`; the bare iD is extracted from either input form
    # (bare or full URL) via {Hyrax::OrcidValidator.extract_bare_orcid}, so the
    # caller does not need to normalize first.
    #
    # @param value [String, nil] a bare ORCID iD (`0000-0000-0000-0000`) or the
    #   full URL form
    # @param name [String, nil] the sibling's display value; used in the
    #   accessibility / hover label ("ORCID iD for Hosseini, Mohammad").
    #   When blank, falls back to the plain "ORCID iD" alt text.
    # @return [ActiveSupport::SafeBuffer, nil] the badge HTML, or nil when
    #   +value+ is blank or unparseable.
    def orcid_badge(value, name: nil)
      bare_id = Hyrax::OrcidValidator.extract_bare_orcid(from: value.to_s)
      return nil if bare_id.blank?

      alt = t('hyrax.compound_fields.orcid.badge_alt', default: 'ORCID iD')
      label = name.present? ? t('hyrax.compound_fields.orcid.badge_aria', name: name, default: "ORCID iD for #{name}") : alt
      link_to "https://orcid.org/#{bare_id}",
              class: 'hyrax-compound-orcid-badge',
              target: '_blank',
              rel: 'noopener noreferrer',
              'aria-label' => label,
              title: label do
        image_tag('orcid.png', alt: alt)
      end
    end

    private

    # Options from a QA local authority. Uses {Hyrax::TolerantSelectService} so
    # an authority file that omits `active:` treats its terms as active rather
    # than raising, matching ordinary controlled fields.
    def authority_options(authority_name)
      return [] if authority_name.blank?
      Hyrax::TolerantSelectService.new(authority_name).select_active_options
    rescue StandardError => e
      Hyrax.logger.debug("compound_subproperty_options: #{authority_name}: #{e.message}")
      []
    end

    # Append the stored value as its own option when it is not already present,
    # so a value no longer offered by the authority/list still renders.
    def ensure_current_value(options, current_value)
      return options if current_value.blank?
      return options if options.any? { |(_label, id)| id.to_s == current_value.to_s }
      options + [[current_value.to_s, current_value.to_s]]
    end
  end
end
