# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Resolves a `controlled` compound sub-field's stored id to its display term
  # (via inline `values:` or a QA `authority:`). Non-controlled sub-fields and
  # ids with no matching term fall back to the value itself.
  class CompoundSubfieldLabeler
    ##
    # @param spec [Hash, nil] the normalized sub-field spec
    #   (`{ type:, authority:, values: }`) from {Hyrax::CompoundSchema}
    # @param value [Object] the stored value (id for controlled sub-fields)
    #
    # @return [String] the term to display
    def self.label_for(spec, value)
      return value.to_s if spec.nil? || spec[:type].to_s != 'controlled' || value.blank?

      if spec[:values].present?
        label_from_values(spec[:values], value)
      elsif spec[:authority].present?
        label_from_authority(spec[:authority], value)
      else
        value.to_s
      end
    end

    def self.label_from_values(values, value)
      pair = Array(values).find { |(_label, id)| id.to_s == value.to_s }
      pair ? pair.first.to_s : value.to_s
    end
    private_class_method :label_from_values

    def self.label_from_authority(authority_name, value)
      Hyrax::TolerantSelectService.new(authority_name).label(value.to_s) { value.to_s }
    rescue StandardError => e
      Hyrax.logger.debug("CompoundSubfieldLabeler: #{authority_name}: #{e.message}")
      value.to_s
    end
    private_class_method :label_from_authority
  end
end
