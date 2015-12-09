require 'spec_helper'

describe 'MultiValueWithHelpInput', type: :input do
  subject { input_for file, field, as: :multi_value_with_help, required: true }
  let(:file) { FileSet.new }

  context "when the field has a translation" do
    let(:field) { :language }
    before do
      allow_any_instance_of(MultiValueWithHelpInput).to receive(:raw_label_text).and_return('Language')
      allow_any_instance_of(MultiValueWithHelpInput).to receive(:translate_from_namespace).and_return('default translation')
      allow_any_instance_of(MultiValueWithHelpInput).to receive(:translate_from_namespace).with(:metadata_help).and_return(
        'The language of the file content.'
      )
    end

    it 'renders help icon' do
      expect(subject).to have_selector('a[data-toggle=popover][data-original-title=Language]')
      expect(subject).to have_selector('a[data-toggle=popover][data-content="The language of the file content."]')
      expect(subject).to have_selector('i.help-icon')
    end
  end

  context "when the field doesn't have a translation" do
    let(:field) { :date_modified }
    it 'renders help icon' do
      expect(subject).to have_selector('a[data-toggle=popover][data-original-title="Date modified"]')
      expect(subject).to have_selector('a[data-toggle=popover][data-content="Date modified"]')
      expect(subject).to have_selector('i.help-icon')
    end
  end
end
