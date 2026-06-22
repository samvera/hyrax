# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::RichTextValidator do
  subject(:validator) { described_class.new(profile, warnings) }
  let(:warnings) { [] }

  def rich_text_form
    { 'form' => { 'input_type' => 'rich_text' } }
  end

  describe '#validate!' do
    context 'when a rich_text property is free text (no controlled vocabulary)' do
      let(:profile) do
        { 'properties' => {
          'context_narrative' => rich_text_form.merge('controlled_values' => { 'sources' => ['null'] })
        } }
      end

      it 'does not warn' do
        validator.validate!
        expect(warnings).to be_empty
      end
    end

    context 'when a rich_text property declares a real controlled_values source' do
      let(:profile) do
        { 'properties' => {
          'subject' => rich_text_form.merge('controlled_values' => { 'sources' => ['loc/subjects'] })
        } }
      end

      it 'warns about the controlled-vocabulary conflict and names the source' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('subject', 'loc/subjects', 'rich_text'))
      end
    end

    context 'when rich_text is declared on a built-in controlled field' do
      let(:profile) { { 'properties' => { 'rights_statement' => rich_text_form } } }

      it 'warns even though no real source is declared' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('rights_statement', 'rich_text'))
      end
    end

    context 'when rich_text is declared on a compound subproperty that is type: controlled' do
      let(:profile) do
        { 'properties' => {
          'compound_rights_statement' => rich_text_form.merge('type' => 'controlled', 'authority' => 'rights_statements')
        } }
      end

      it 'warns about the controlled type conflict' do
        validator.validate!
        expect(warnings).to contain_exactly(a_string_including('compound_rights_statement', 'controlled'))
      end
    end

    context 'when a controlled property does not use rich_text' do
      let(:profile) do
        { 'properties' => {
          'rights_statement' => { 'controlled_values' => { 'sources' => ['rights_statements'] } }
        } }
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
