require 'spec_helper'

describe 'batch/edit.html.erb' do
  let(:batch) { stub_model(Batch, id: '123') }
  let(:generic_file) { stub_model(GenericFile, id: nil, depositor: 'bob', rights: ['']) }
  let(:form) { Sufia::Forms::BatchEditForm.new(generic_file) }

  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign :batch, batch
    assign :form, form
    render
  end

  it "should draw the page" do
    # form
    expect(rendered).to have_selector "form#new_generic_file"
    # should have browser validations
    expect(rendered).not_to have_selector "form#new_generic_file[novalidate]"

    # tooltip for visibility
    expect(rendered).to have_selector "span#visibility_tooltip a i.help-icon"

    # tooltip for share_with
    expect(rendered).to have_selector "span#share_with_tooltip a i.help-icon"

    # access rights
    expect(rendered).to have_selector("div#rightsModal .modal-dialog .modal-content")
    expect(rendered).to have_selector('select#generic_file_rights[name="generic_file[rights][]"]')
    page = Capybara::Node::Simple.new(rendered)
    page.all('select#generic_file_rights option').each do |elem|
      expect(elem.value).to_not be_empty
    end

  end
end

