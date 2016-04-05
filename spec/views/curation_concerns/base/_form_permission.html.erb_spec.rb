require 'spec_helper'

describe 'curation_concerns/base/_form_permission.html.erb' do
  let(:curation_concern) { GenericWork.new }
  before do
    f = double('form', object: curation_concern,
                       object_name: nil,
                       input: nil,
                       radio_button: nil)
    render partial: "curation_concerns/base/form_permission", locals: { f: f }
  end

  it 'has a permissions note' do
    expect(rendered).to have_content('Please note, making something visible to the world')
  end
end
