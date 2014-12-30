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

  it "should draw tooltip for visibility" do
    expect(rendered).to have_selector "span#visibility_tooltip a i.help-icon"
  end

  it "should draw tooltip for share_with" do
    expect(rendered).to have_selector "span#share_with_tooltip a i.help-icon"
  end

  context "rights" do
    it "should have a modal" do
      expect(rendered).to have_selector("div#rightsModal .modal-dialog .modal-content")
    end

    it "should allow setting many rights" do
      expect(rendered).to have_selector('select#generic_file_rights[name="generic_file[rights][]"]')
    end

    it "should not have an empty rights element" do
      page = Capybara::Node::Simple.new(rendered)
      page.all('select#generic_file_rights option').each do |elem|
        expect(elem.value).to_not be_empty
      end
    end
  end
end

