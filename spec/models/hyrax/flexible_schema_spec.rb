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
          attributes.each do |key, values|
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
end
