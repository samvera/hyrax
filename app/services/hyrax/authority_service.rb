# frozen_string_literal: true
module Hyrax
  # Shared behavior for authority-backed services. Module-level services
  # (such as {Hyrax::ResourceTypesService}) `extend` this module to gain a
  # tolerant `label` / `active?` / `include_current_value` API plus the
  # declarative macros described below.
  #
  # The tolerant methods are intentionally forgiving of off-authority values:
  # `label` falls back to the id itself, `active?` returns false for ids that
  # aren't present in the authority at all, and `include_current_value`
  # preserves such values in edit forms so they are not silently dropped on
  # save.
  #
  # ## Declarative macros
  #
  # Hosts use the {#authority_name} and {#microdata_namespace} macros to
  # declare the wrapped subauthority and the i18n namespace used for
  # schema.org type lookup. These macros generate the rest of the host's
  # API for free:
  #
  #     module Hyrax
  #       module DisciplineService
  #         extend Hyrax::AuthorityService
  #
  #         authority_name 'discipline'
  #         microdata_namespace 'type.'
  #       end
  #     end
  #
  # `authority_name` provides `authority`, `authority=`, `select_options`,
  # and `select_all_options` (the latter is an alias of the former — both
  # names are in use in the wild). `microdata_namespace` provides
  # `microdata_type`.
  #
  # @note This module is intended for use via `extend` on a host module. The
  #   macros define singleton methods on the host and are not available via
  #   `include`. Hosts that need instance-level tolerant lookup should
  #   subclass {Hyrax::QaSelectService} instead.
  module AuthorityService
    # Declares which Qa::Authorities::Local subauthority this host wraps,
    # generating `authority`, `authority=`, `select_options`, and
    # `select_all_options` accessors on the host.
    #
    # @param subauthority_name [String] the YAML subauthority name (e.g.
    #   `'discipline'`)
    def authority_name(subauthority_name)
      define_singleton_method(:authority) do
        @authority ||= Qa::Authorities::Local.subauthority_for(subauthority_name)
      end

      define_singleton_method(:authority=) do |value|
        @authority = value
      end

      define_singleton_method(:select_all_options) do
        authority.all.map { |element| [element[:label], element[:id]] }
      end
      singleton_class.alias_method(:select_options, :select_all_options)
    end

    # Declares the Microdata i18n namespace this host uses for schema.org
    # type lookup, generating a `microdata_type(id)` method on the host.
    #
    # @param namespace [String] the Microdata key prefix (e.g. `'type.'`,
    #   `'resource_type.'`, `'accessibility_feature_type.'`)
    def microdata_namespace(namespace)
      define_singleton_method(:microdata_type) do |id|
        return Hyrax.config.microdata_default_type if id.nil?
        Microdata.fetch("#{namespace}#{id}", default: Hyrax.config.microdata_default_type)
      end
    end

    # @param id [String]
    # @return [String] the label for the authority entry, falling back to the
    #   id itself when no matching term is found.
    #
    # @yield when no 'term' value is present for the id
    # @yieldreturn [String] an alternate label to return
    def label(id, &block)
      block ||= ->(_key) { id }
      authority.find(id).fetch('term', &block)
    end

    # @return [Boolean] whether the id is an active entry. Returns false for
    #   ids that aren't present in the authority at all, so a caller can treat
    #   unknown ids as inactive (and preserve them in edit forms via
    #   {#include_current_value}).
    def active?(id)
      result = authority.find(id)
      return false if result.blank?
      result.fetch('active', true)
    end

    # Preserves an off-authority value as a forced-select option in a Simple
    # Form input so it is not silently dropped on save. Intended for use as a
    # Simple Form `item_helper:` callback or to augment a `collection:` array
    # in a partial.
    def include_current_value(value, _index, render_options, html_options)
      force_select = html_options[:class].is_a?(Array) ? [' force-select'] : ' force-select'
      unless value.blank? || active?(value)
        html_options[:class] += force_select
        render_options += [[label(value), value]]
      end
      [render_options, html_options]
    end
  end
end
