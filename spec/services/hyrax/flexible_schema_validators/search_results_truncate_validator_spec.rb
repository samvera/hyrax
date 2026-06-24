# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::SearchResultsTruncateValidator do
  subject(:validator) { described_class.new(profile, warnings) }
  let(:warnings) { [] }

  describe '#validate!' do
    context 'when search_results_truncate is paired with render_as: html' do
      let(:profile) do
        { 'properties' => {
          'context_narrative' => { 'view' => { 'render_as' => 'html', 'search_results_truncate' => 300 } }
        } }
      end

      it 'does not warn' do
        validator.validate!
        expect(warnings).to be_empty
      end
    end

    context 'when search_results_truncate is declared without render_as: html' do
      let(:profile) do
        { 'properties' => {
          'note' => { 'view' => { 'search_results_truncate' => 300 } }
        } }
      end

      it 'warns that the setting has no effect' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('note', 'search_results_truncate', 'render_as: html'))
      end
    end

    context 'when search_results_truncate is set with a non-html render_as' do
      let(:profile) do
        { 'properties' => {
          'note' => { 'view' => { 'render_as' => 'linked', 'search_results_truncate' => 50 } }
        } }
      end

      it 'warns' do
        validator.validate!
        expect(warnings.size).to eq(1)
      end
    end

    context 'when a field has render_as: html but no truncate setting' do
      let(:profile) do
        { 'properties' => { 'context_narrative' => { 'view' => { 'render_as' => 'html' } } } }
      end

      it 'does not warn' do
        validator.validate!
        expect(warnings).to be_empty
      end
    end

    context 'when the profile has no properties' do
      let(:profile) { {} }

      it 'does not raise' do
        expect { validator.validate! }.not_to raise_error
      end
    end
  end
end
