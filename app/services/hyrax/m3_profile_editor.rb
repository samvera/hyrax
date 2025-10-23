# frozen_string_literal: true
module Hyrax
  class M3ProfileEditor
    attr_accessor :profile_path

    def initialize(profile_path)
      @profile_path = profile_path
    end

    def profile_data
      return @profile_data if @profile_data
      # Use the provided path or default to the dassie m3_profile.yaml
      raise "Error: Profile file not found at #{profile_path}" unless File.exist?(profile_path)

      Rails.logger.debug "Processing M3 profile at: #{profile_path}"

      # Load the YAML file
      @profile_data = YAML.load_file(profile_path)
    end

    def find_i18n(label_value)
      I18n.reverse_lookup(label_value, scope: [:blacklight, :search, :fields, :show]) ||
        I18n.reverse_lookup(label_value, scope: [:blacklight, :search, :fields, :index]) ||
        label_value
    end

    def save
      File.write(@profile_path, profile_data.to_yaml)
      Rails.logger.debug "Updated profile saved to: #{@profile_path}"
    end
  end
end
