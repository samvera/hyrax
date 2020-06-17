# frozen_string_literal: true

RSpec.describe Hyrax::ContactFormHelper, type: :helper do
  describe '#contact_form_issue_type_options' do
    it 'has a nil (label) option first' do
      expect(helper.contact_form_issue_type_options.first).to match([an_instance_of(String), nil])
    end

    it 'has string options' do
      expect(helper.contact_form_issue_type_options[1..-1]).to all(be_an_instance_of(String))
    end
  end
end
