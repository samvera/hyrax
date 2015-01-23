require 'spec_helper'

describe 'SelectWithHelpInput', type: :input do
  subject { input_for form, :resource_type, options }
  let(:file) { GenericFile.new }
  let(:form) { Sufia::Forms::BatchEditForm.new(file) }
  let(:base_options) { { as: :select_with_help, collection: Sufia.config.resource_types,
                         input_html: { class: 'form-control', multiple: true } } }
  let(:options) { base_options }

  it "should not be required by default" do
      expect(subject).to have_selector 'select'
      expect(subject).not_to match /required/
  end
end

