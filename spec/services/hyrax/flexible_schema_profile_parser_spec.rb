# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::FlexibleSchemaProfileParser do
  let(:profile_file_path) { File.join(fixture_path, 'files', 'm3_profile.yaml') }
  let(:profile) { YAML.load_file(profile_file_path) }
  let(:parser) { described_class.new(profile) }

  describe '.class_names_for' do
    it 'initializes and calls class_names' do
      expect(described_class.class_names_for(profile)).to eq(described_class.new(profile).class_names)
    end
  end

  describe '#class_names' do
    let(:class_names) { parser.class_names }

    it 'returns a hash' do
      expect(class_names).to be_a(Hash)
    end

    it 'includes all classes from the profile' do
      expect(class_names.keys).to match_array(profile['classes'].keys)
    end

    it 'populates class hashes with properties and leaves them empty for classes without any' do
      (profile['classes'].keys - ['Collection']).each do |class_name|
        expect(class_names[class_name]).not_to be_empty
      end

      expect(class_names['Collection']).to be_empty
    end

    context 'with property mappings' do
      let(:work_properties) { class_names['Monograph'] }
      let(:title_property) { work_properties['title'] }
      let(:date_property) { work_properties['date_modified'] }

      it 'maps m3 values to hyrax expectations' do
        expect(title_property).to include('type', 'predicate', 'index_keys', 'multiple')
        expect(title_property['predicate']).to eq('http://purl.org/dc/terms/title')
        expect(title_property['multiple']).to be true
      end

      it 'correctly looks up property type' do
        expect(date_property['type']).to eq('date_time')
      end

      it 'handles form requirements based on cardinality' do
        fileset_properties = class_names['Hyrax::FileSet']
        required_property = fileset_properties['creator']

        expect(required_property['cardinality']['minimum']).to eq(1)
        expect(required_property.dig('form', 'required')).to be true
      end
    end
  end
end
