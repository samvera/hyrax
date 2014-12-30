require 'spec_helper'

describe 'SelectWithModalHelpInput', type: :input do
  subject { input_for file, :rights, options }
  let(:file) { GenericFile.new }
  let(:base_options) { { as: :select_with_modal_help, required: true, collection: Sufia.config.cc_licenses } }
  let(:options) { base_options }

  context "when a blank is requested" do
    let(:options) { base_options.merge(include_blank: true) }
    it 'renders a blank option' do
      expect(subject).to have_selector 'select option[value=""]'
    end
  end

  context "when a blank is not requested" do
    it 'has no blanks' do
      expect(subject).to have_selector 'select option:first-child', text: 'Attribution 3.0 United States'
    end
  end
end
