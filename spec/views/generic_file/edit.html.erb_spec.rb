require 'spec_helper'

describe 'file_sets/edit.html.erb', :no_clean do
  describe 'when the file has two or more resource types' do
    let(:resource_version) do
      ActiveFedora::VersionsGraph::ResourceVersion.new.tap do |v|
        v.uri = 'http://example.com/version1'
        v.label = 'version1'
        v.created = '2014-12-09T02:03:18.296Z'
      end
    end
    let(:version_list) { Sufia::VersionListPresenter.new([resource_version]) }
    let(:versions_graph) { double(all: [version1]) }
    let(:content) { double('content', mimeType: 'application/pdf') }

    let(:file_set) do
      stub_model(FileSet, id: '123',
                              depositor: 'bob',
                              resource_type: ['Book', 'Dataset'])
    end

    let(:form) do
      CurationConcerns::Forms::FileSetEditForm.new(file_set)
    end

    before do
      allow(file_set).to receive(:content).and_return(content)
      allow(controller).to receive(:current_user).and_return(stub_model(User))
      assign(:file_set, file_set)
      assign(:form, form)
      assign(:version_list, version_list)
    end

    let(:page) do
      render
      Capybara::Node::Simple.new(rendered)
    end

    it "only draws one resource_type multiselect" do
      expect(page).to have_selector("select#file_set_resource_type", count: 1)
    end
  end
end
