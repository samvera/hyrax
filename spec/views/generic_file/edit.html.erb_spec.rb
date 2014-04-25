require 'spec_helper'

describe 'generic_files/edit.html.erb', :type => :view do
  describe 'when the file has two or more resource types' do
    let(:generic_file) {
      content = double('content', versions: [], mimeType: 'application/pdf')
      stub_model(GenericFile, id: '123', noid: '123',
        depositor: 'bob',
        resource_type: ['Book', 'Dataset'],
        content: content)
    }

    before do
      allow(controller).to receive(:current_user).and_return(stub_model(User))
      assign(:generic_file, generic_file)
    end

    it "should only draw one resource_type multiselect" do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_selector("select#generic_file_resource_type", count: 1)
    end
  end
end
