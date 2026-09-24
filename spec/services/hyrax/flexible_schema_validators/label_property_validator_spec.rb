# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::LabelPropertyValidator do
  subject(:validator) { described_class.new(context) }
  let(:context) { Hyrax::FlexibleSchemaValidators::ValidationContext.new(profile: profile) }
  let(:errors) { validator.violations.map(&:message) }

  let(:file_set_model) { 'Hyrax::FileSet' }

  before do
    allow(Hyrax.config).to receive(:file_set_model).and_return(file_set_model)
    validator.validate!
  end

  describe '#validate!' do
    context 'when label is available on the file set model' do
      let(:profile) do
        { 'properties' => { 'label' => { 'available_on' => { 'class' => ['Hyrax::FileSet'] } } } }
      end

      it 'reports nothing' do
        expect(errors).to be_empty
      end
    end

    context 'when label is available on the file set model among others' do
      let(:profile) do
        { 'properties' => { 'label' => { 'available_on' => { 'class' => ['Monograph', 'Hyrax::FileSet'] } } } }
      end

      it 'reports nothing' do
        expect(errors).to be_empty
      end
    end

    context 'when the label property is absent' do
      let(:profile) { { 'properties' => { 'title' => {} } } }

      it 'requires one' do
        expect(errors).to contain_exactly('A `label` property is required.')
      end
    end

    context 'when label is not available on the file set model' do
      let(:profile) do
        { 'properties' => { 'label' => { 'available_on' => { 'class' => ['Monograph'] } } } }
      end

      it 'names the file set model' do
        expect(errors).to contain_exactly('Label must be available on Hyrax::FileSet.')
      end
    end

    context 'when label declares no available_on at all' do
      let(:profile) { { 'properties' => { 'label' => {} } } }

      it 'names the file set model' do
        expect(errors).to contain_exactly('Label must be available on Hyrax::FileSet.')
      end
    end

    context 'when the configured file set model carries a leading ::' do
      let(:file_set_model) { '::Hyrax::FileSet' }
      let(:profile) do
        { 'properties' => { 'label' => { 'available_on' => { 'class' => ['Hyrax::FileSet'] } } } }
      end

      it 'reports nothing' do
        expect(errors).to be_empty
      end
    end
  end
end
