require 'spec_helper'

describe 'batch_edits/edit.html.erb' do
  let(:generic_file) { stub_model(GenericFile, id: nil, depositor: 'bob', rights: ['']) }

  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign :names, ['title 1', 'title 2']
    assign :terms, [:description, :rights]
    assign :generic_file, generic_file
    render
  end

  it "should draw tooltip for description" do
    expect(rendered).to have_selector ".generic_file_description a i.help-icon"
  end
end


