require 'spec_helper'

describe 'collections/_form.html.erb', :type => :view do
  describe 'when the collection edit form is rendered' do
    let(:collection) { Collection.new(title: 'the title', description: 'the description',
                                       creator: ['the creator'])}

    let(:collection_form) { Sufia::Forms::CollectionEditForm.new(collection) }

    before do
      controller.request.path_parameters[:id] = 'j12345'
      assign(:form, collection_form)
    end

    it "should draw the metadata fields for collection" do
      render
      expect(rendered).to have_selector("input#collection_title", count: 1)
      expect(rendered).to_not have_selector("div#additional_title_clone button.adder")
      expect(rendered).to have_selector("input#collection_creator", count: 1)
      expect(rendered).to have_selector("div#additional_creator_clone button.adder")
      expect(rendered).to have_selector("textarea#collection_description", count: 1)
      expect(rendered).to have_selector("input#collection_contributor", count: 1)
      expect(rendered).to have_selector("input#collection_tag", count: 1)
      expect(rendered).to have_selector("input#collection_subject", count: 1)
      expect(rendered).to have_selector("input#collection_publisher", count: 1)
      expect(rendered).to have_selector("input#collection_date_created", count: 1)
      expect(rendered).to have_selector("input#collection_language", count: 1)
      expect(rendered).to have_selector("input#collection_identifier", count: 1)
      expect(rendered).to have_selector("input#collection_based_near", count: 1)
      expect(rendered).to have_selector("input#collection_related_url", count: 1)
      expect(rendered).to have_selector("select#collection_rights", count: 1)
      expect(rendered).to have_selector("select#collection_resource_type", count: 1)
    end
  end
end
