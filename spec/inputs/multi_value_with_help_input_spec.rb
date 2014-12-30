require 'spec_helper'

describe 'MultiValueWithHelpInput', type: :input do
  subject { input_for file, field, { as: :multi_value_with_help, required: true } }
  let(:file) { GenericFile.new }

  context "when the field has a translation" do
    let(:field) { :language }
    it 'renders help icon' do
      expect(subject).to have_selector('a[rel=popover][data-original-title=Language]')
      expect(subject).to have_selector('a[rel=popover][data-content="The language of the file content."]')
      expect(subject).to have_selector('i.help-icon')
    end
  end

  context "when the field doesn't have a translation" do
    let(:field) { :date_modified }
    it 'renders help icon' do
      expect(subject).to have_selector('a[rel=popover][data-original-title="Date modified"]')
      expect(subject).to have_selector('a[rel=popover][data-content="Date modified"]')
      expect(subject).to have_selector('i.help-icon')
    end
  end

end
