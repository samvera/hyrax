# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_form.html.erb', type: :view do
  let(:collection) { build :collection_resource }
  let(:collection_form) { Hyrax::Forms::ResourceForm.for(resource: collection) }
  let(:banner_info) { { file: "banner.gif", alttext: "Banner alt text" } }
  let(:logo_info) { [{ file: "logo.gif", alttext: "Logo alt text", linkurl: "http://abc.com" }] }

  before do
    controller.request.path_parameters[:id] = 'j12345'
    assign(:form, collection_form)
    assign(:collection, collection)
    assign(:banner_info, banner_info)
    assign(:logo_info, logo_info)
  end

  context 'with secondary terms' do
    before do
      allow(collection_form)
        .to receive(:display_additional_fields?)
        .and_return(true)
    end

    it "draws the metadata fields for collection" do
      render

      expect(rendered).to have_selector("input#collection_title")
      expect(rendered).to have_selector("span.required-tag", text: "required")
      expect(rendered).not_to have_selector("div#additional_title.multi_value")
      expect(rendered).to have_selector("input#collection_creator.multi_value")
      expect(rendered).to have_selector("textarea#collection_description")
      expect(rendered).to have_selector("input#collection_contributor")
      expect(rendered).to have_selector("input#collection_keyword")
      expect(rendered).to have_selector("input#collection_subject")
      expect(rendered).to have_selector("input#collection_publisher")
      expect(rendered).to have_selector("input#collection_date_created")
      expect(rendered).to have_selector("input#collection_language")
      expect(rendered).to have_selector("input#collection_identifier")
      expect(rendered).to have_selector("div.controlled_vocabulary.collection_based_near")
      expect(rendered).to have_selector("input#collection_related_url")
      expect(rendered).to have_selector("select#collection_license")
      expect(rendered).to have_selector("select#collection_resource_type")
      expect(rendered).not_to have_selector("input#collection_visibility")
      expect(rendered).to have_content('Additional fields')
    end
  end

  context 'with no secondary terms' do
    before do
      allow(collection_form)
        .to receive(:display_additional_fields?)
        .and_return(false)
    end

    it 'does not render additional fields button' do
      render
      expect(rendered).not_to have_content('Additional fields')
    end
  end
end
