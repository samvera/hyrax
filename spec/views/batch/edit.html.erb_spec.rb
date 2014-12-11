require 'spec_helper'

describe 'batch/edit.html.erb', :type => :view do
  let( :batch ) {
    stub_model(Batch, id: '123')
  }

  let(:content) { double('content', versions: [], mimeType: 'application/pdf') }
  let(:generic_file) {
    stub_model(GenericFile, id: '321', noid: '321', depositor: 'bob', rights: [''])
  }


  before do
    allow(generic_file).to receive(:content).and_return(content)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    controller.request.path_parameters[:id] = "123"
    assign :batch, batch
    assign :generic_file, generic_file
    render
    @page = Capybara::Node::Simple.new(rendered)
  end

  it "should draw tooltip for visibility" do
    expect(@page).to have_selector("span#visibility_tooltip", count: 1)
    expect(@page).to have_selector("a#generic_file_visibility_help", count: 1)
  end

  it "should draw tooltip for share_with" do
    expect(@page).to have_selector("span#share_with_tooltip", count: 1)
    expect(@page).to have_selector("a#generic_file_share_with_help", count: 1)
  end

  context "rights" do
    it "should have a modal" do
      expect(@page).to have_selector("div#rightsModal .modal-dialog .modal-content")
    end

    it "should allow setting many rights" do
      expect(@page).to have_selector('select#generic_file_rights[name="generic_file[rights][]"]')
    end
  
    it "should not have an empty rights element" do
      @page.all('select#generic_file_rights option').each do |elem| 
        expect(elem.value).to_not be_empty 
      end
    end
  end
end

