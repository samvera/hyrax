# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::FlexibleSchema, type: :model do
  let(:profile_file_path) { File.join(fixture_path, 'files', 'm3_profile.yaml') }
  let(:profile_data) { YAML.load_file(profile_file_path) }

  subject { described_class.create(profile: profile_data) }

  describe '#title' do
    it 'returns the correct title' do
      responsibility_statement = profile_data['profile']['responsibility_statement']
      expect(subject.title).to eq("#{responsibility_statement} - version #{subject.id}")
    end
  end

  describe '#attributes_for' do
    context 'when class_name exists' do
      it 'returns the correct attributes for each class' do
        profile_data['classes'].keys.each do |class_name|
          attributes = subject.attributes_for(class_name)
          expect(attributes).to be_a(Hash)
          attributes.each do |_key, values|
            expect(values).to include('type', 'predicate', 'index_keys', 'multiple')
          end
        end
      end
    end

    context 'when class_name does not exist' do
      it 'returns nil' do
        expect(subject.attributes_for('NonExistentClass')).to be_nil
      end
    end
  end

  describe '#mappings_data_for' do
    before do
      allow(described_class).to receive(:current_version).and_return(subject.profile)
    end

    context 'when mapping exists' do
      let(:mapping_data) { described_class.mappings_data_for('simple_dc_pmh') }
      let(:result_data) do
        { "title" => { "indexing" => ["title_sim", "title_tesim"],
                       "mappings" => { "simple_dc_pmh" => "dc:title" } } }
      end

      it 'returns the correct mappings data' do
        expect(mapping_data).to eq(result_data)
      end
    end

    context 'when mapping does not exist' do
      it 'returns an empty hash' do
        mapping_data = described_class.mappings_data_for('non_existent_mapping')
        expect(mapping_data).to eq({})
      end
    end

    context 'when profile does not exist' do
      before do
        allow(described_class).to receive(:current_version).and_return(nil)
      end

      it 'returns an empty hash' do
        mapping_data = described_class.mappings_data_for('simple_dc_pmh')
        expect(mapping_data).to eq({})


  describe 'property name resolution' do
    let(:profile_with_names) do
      {
        'profile' => {
          'responsibility_statement' => 'Test Profile',
          'date_modified' => '2024-06-01'
        },
        'properties' => {
          'title_primary' => {
            'name' => 'title',
            'available_on' => { 'class' => ['GenericWorkResource'], 'context' => ['primary_context'] },
            'range' => 'http://www.w3.org/2001/XMLSchema#string',
            'property_uri' => 'http://purl.org/dc/terms/title'
          },
          'title_alternative' => {
            'name' => 'title',
            'available_on' => { 'class' => ['GenericWorkResource'], 'context' => ['alternative_context'] },
            'range' => 'http://www.w3.org/2001/XMLSchema#string',
            'property_uri' => 'http://purl.org/dc/terms/alternative'
          },
          'description_fallback' => {
            'available_on' => { 'class' => ['GenericWorkResource'] },
            'range' => 'http://www.w3.org/2001/XMLSchema#string',
            'property_uri' => 'http://purl.org/dc/terms/description'
          }
        },
        'classes' => {
          'GenericWorkResource' => { 'display_label' => 'Generic Work' }
        },
        'contexts' => {
          'primary_context' => { 'display_label' => 'Primary Context' },
          'alternative_context' => { 'display_label' => 'Alternative Context' }
        }
      }
    end

    subject { described_class.create(profile: profile_with_names) }

    context 'with name attribute' do
      it 'uses name for storage key' do
        attributes = subject.attributes_for('GenericWorkResource')

        expect(attributes).to have_key('title')
        expect(attributes).not_to have_key('title_primary')
        expect(attributes).not_to have_key('title_alternative')
      end
    end

    context 'without name attribute' do
      it 'falls back to YAML key' do
        attributes = subject.attributes_for('GenericWorkResource')

        expect(attributes).to have_key('description_fallback')
      end
    end

    context 'conflict validation' do
      it 'allows same name with non-overlapping contexts' do
        expect(subject).to be_valid
      end

      it 'rejects same name with overlapping contexts' do
        conflicting_profile = profile_with_names.deep_dup
        conflicting_profile['properties']['title_conflict'] = {
          'name' => 'title',
          'available_on' => {
            'class' => ['GenericWorkResource'],
            'context' => ['primary_context']  # Conflicts with title_primary
          },
          'range' => 'http://www.w3.org/2001/XMLSchema#string',
          'property_uri' => 'http://purl.org/dc/terms/title'
        }

        conflicting_schema = described_class.create(profile: conflicting_profile)
        expect(conflicting_schema).not_to be_valid
        expect(conflicting_schema.errors[:profile]).to include(/Property name 'title' conflicts/)
      end

      it 'rejects same name with overlapping classes and no contexts' do
        conflicting_profile = profile_with_names.deep_dup
        conflicting_profile['properties']['title_no_context'] = {
          'name' => 'title',
          'available_on' => {
            'class' => ['GenericWorkResource']
            # No context specified
          },
          'range' => 'http://www.w3.org/2001/XMLSchema#string',
          'property_uri' => 'http://purl.org/dc/terms/title'
        }

        conflicting_schema = described_class.create(profile: conflicting_profile)
        expect(conflicting_schema).not_to be_valid
        expect(conflicting_schema.errors[:profile]).to include(/Property name 'title' conflicts/)
      end
    end
  end
end
