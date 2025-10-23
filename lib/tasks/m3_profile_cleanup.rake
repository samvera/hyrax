# frozen_string_literal: true

require 'yaml'
require 'pathname'

namespace :hyrax do
  namespace :metadata do
    desc "Clean up display_label attributes in M3 profile YAML file"
    task :update_labels, [:profile_path] => :environment do |_task, args|
      # Force i18n to load
      I18n.t('blacklight.search.fields.show.title_tesim')

      profile_editor = Hyrax::M3ProfileEditor.new(Rails.root.join(args[:profile_path]) || Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml'))

      profile_editor.profile_data['properties'].each do |property_name, property_data|
        default_label = case property_data['display_label']
                        when String
                          property_data['display_label']
                        when Hash
                          property_data['display_label']['default']
                        else
                          property_name.humanize
                        end
        existing_hash = property_data['view']&.fetch('label', nil)
        existing_hash = nil if !existing_hash.is_a?(Hash) || existing_hash.keys.size <= 1
        existing_hash ||= property_data['display_label'] if property_data['display_label'].is_a?(Hash) && property_data['display_label'].keys.size > 1

        profile_editor.profile_data['properties'][property_name]['display_label'] = existing_hash.presence || {}
        profile_editor.profile_data['properties'][property_name]['display_label']['default'] = profile_editor.find_i18n(default_label)
        profile_editor.profile_data['properties'][property_name]['view'].delete('label') if profile_editor.profile_data['properties'][property_name]['view'].present?
      end
      profile_editor.save
    end
  end
end
