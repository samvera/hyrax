# frozen_string_literal: true
module Hyrax
  module ResourceTypesService
    def self.authority
      @authority ||= Qa::Authorities::Local.subauthority_for('resource_types')
    end

    def self.authority=(val)
      @authority = val
    end

    def self.select_options
      authority.all.map do |element|
        [element[:label], element[:id]]
      end
    end

    # @param id [String]
    # @return [String] the label for the authority, falling back to the id
    #   itself when no matching term exists.
    def self.label(id)
      authority.find(id).fetch('term') { id }
    end

    # @param id [String]
    # @return [Boolean] whether the id is an active term in the authority.
    #   Returns false for ids that aren't in the authority at all, so the
    #   caller can treat unknown ids as inactive (and preserve them in
    #   edit forms via {.include_current_value}).
    def self.active?(id)
      result = authority.find(id)
      return false if result.empty?
      result.fetch('active', true)
    end

    # Preserve an off-authority resource_type value as an additional, selected
    # option in an edit form, so saving the record does not silently drop the
    # value. Mirrors {Hyrax::QaSelectService#include_current_value}.
    def self.include_current_value(value, _index, render_options, html_options)
      force_select = html_options[:class].is_a?(Array) ? [' force-select'] : ' force-select'
      unless value.blank? || active?(value)
        html_options[:class] += force_select
        render_options += [[label(value), value]]
      end
      [render_options, html_options]
    end

    ##
    # @param [String, nil] id identifier of the resource type
    #
    # @return [String] a schema.org type. Gives the default type if `id` is nil.
    def self.microdata_type(id)
      return Hyrax.config.microdata_default_type if id.nil?
      Microdata.fetch("resource_type.#{id}", default: Hyrax.config.microdata_default_type)
    end
  end
end
