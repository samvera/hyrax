module Sufia
  module CharacterizationBehavior
    extend ActiveSupport::Concern

    class_methods do
      def characterization_terms
        [
          :byte_order, :compression, :height, :width, :height, :color_space,
          :profile_name, :profile_version, :orientation, :color_map, :image_producer,
          :capture_device, :scanning_software, :gps_timestamp, :latitude, :longitude
        ]
      end
    end

    included do
      delegate(*characterization_terms, to: :solr_document)
    end

    def characterized?
      !characterization_metadata.values.compact.empty?
    end

    def characterization_metadata
      @characterization_metadata ||= build_characterization_metadata
    end

    # Override this if you want to inject additional characterization metadata
    # Use a hash of key/value pairs where the value is an Array or String
    # {
    #   term1: ["value"],
    #   term2: ["value1", "value2"],
    #   term3: "a string"
    # }
    def additional_characterization_metadata
      @additional_characterization_metadata ||= {}
    end

    def label_for_term(term)
      term.to_s.titleize
    end

    # Returns an array of characterization values truncated to 250 characters limited
    # to the maximum number of configured values.
    # @param [Symbol] term found in the characterization_metadata hash
    # @return [Array] of truncated values
    def primary_characterization_values(term)
      values = values_for(term)
      values.slice!(Sufia.config.fits_message_length, (values.length - Sufia.config.fits_message_length))
      truncate_all(values)
    end

    # Returns an array of characterization values truncated to 250 characters that are in
    # excess of the maximum number of configured values.
    # @param [Symbol] term found in the characterization_metadata hash
    # @return [Array] of truncated values
    def secondary_characterization_values(term)
      values = values_for(term)
      additional_values = values.slice(Sufia.config.fits_message_length, values.length - Sufia.config.fits_message_length)
      return [] unless additional_values
      truncate_all(additional_values)
    end

    private

      def values_for(term)
        Array.wrap(characterization_metadata[term])
      end

      def truncate_all(values)
        values.map { |v| v.to_s.truncate(250) }
      end

      def build_characterization_metadata
        self.class.characterization_terms.each do |term|
          additional_characterization_metadata[term.to_sym] = send(term)
        end
        additional_characterization_metadata
      end
  end
end
