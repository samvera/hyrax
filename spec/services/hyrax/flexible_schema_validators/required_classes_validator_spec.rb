# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::RequiredClassesValidator do
  subject(:validator) { described_class.new(context) }
  let(:context) do
    Hyrax::FlexibleSchemaValidators::ValidationContext.new(
      profile: profile, required_classes: required_classes
    )
  end

  let(:required_classes) { ['AdminSet', 'Collection', 'FileSet'] }
  let(:errors) { validator.violations.map(&:message) }

  before { validator.validate! }

  describe '#validate!' do
    context 'when every required class is declared' do
      let(:profile) do
        { 'classes' => { 'AdminSet' => {}, 'Collection' => {}, 'FileSet' => {} } }
      end

      it 'reports nothing' do
        expect(errors).to be_empty
      end
    end

    context 'when a required class is missing' do
      let(:profile) { { 'classes' => { 'AdminSet' => {}, 'Collection' => {} } } }

      it 'names the missing class' do
        expect(errors).to contain_exactly('Missing required classes: FileSet.')
      end
    end

    context 'when the profile declares no classes at all' do
      let(:profile) { { 'classes' => {} } }

      it 'names every required class' do
        expect(errors).to contain_exactly('Missing required classes: AdminSet, Collection, FileSet.')
      end
    end

    context 'when a required class is declared with a leading ::' do
      let(:required_classes) { ['::AdminSet'] }
      let(:profile) { { 'classes' => { 'AdminSet' => {} } } }

      it 'treats the two spellings as the same class' do
        expect(errors).to be_empty
      end
    end

    context 'when the profile declares extra classes' do
      let(:profile) do
        { 'classes' => { 'AdminSet' => {}, 'Collection' => {}, 'FileSet' => {}, 'Monograph' => {} } }
      end

      it 'reports nothing' do
        expect(errors).to be_empty
      end
    end
  end
end
