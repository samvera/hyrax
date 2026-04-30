# frozen_string_literal: true
module Hyrax
  ##
  # Validates that controlled vocabulary properties contain only active
  # terms from their corresponding local QA authority.
  #
  # Properties are matched to authorities dynamically via
  # +Qa::Authorities::Local.subauthorities+, using the singularized
  # authority name to match property names on the change set.
  #
  # Only covers local authorities (file-based and table-based).
  # Remote authorities (e.g. Geonames) are out of scope.
  class ControlledVocabularyValidator < ActiveModel::Validator
    def validate(record)
      active_terms_by_property(record).each do |property, terms|
        values = Array.wrap(record.public_send(property)).reject(&:blank?)
        next if values.empty?

        invalid = values.reject { |v| terms.include?(v) }
        invalid.each do |v|
          record.errors.add(property, "#{property.to_s.humanize} contains unrecognized value: #{v}")
        end
      end
    end

    private

    ##
    # @example
    #   # { "license" => ["http://creativecommons.org/licenses/by/4.0/", ...],
    #   #   "resource_type" => ["Article", "Book", ...] }
    #
    # @return [Hash{String => Array<String>}]
    def active_terms_by_property(record)
      authorities = Qa::Authorities::Local.subauthorities

      # { "license" => "licenses", "resource_type" => "resource_types", ... }
      property_to_authority = {}.tap do |hash|
        authorities.each { |name| hash[name.singularize] = name }
      end

      properties = record.fields.keys.map(&:to_s)

      {}.tap do |result|
        (properties & property_to_authority.keys).each do |property|
          authority = Qa::Authorities::Local.subauthority_for(property_to_authority[property])
          terms = authority.all
          next if terms.empty?

          result[property] = terms.filter_map { |term| term[:id] if active?(term) }
        end
      end
    end

    ##
    # Terms without an +active+ field (e.g. resource_types) are
    # treated as active, matching QA's +FileBasedAuthority#all+ behavior.
    def active?(term)
      term.fetch(:active, true) != false
    end
  end
end
