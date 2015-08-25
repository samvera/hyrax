require 'spec_helper'

describe 'generic_works/_generic_work.html.erb', type: :view do
  context 'displaying a generic_file' do
    let(:generic_work) do
      mock_model(SolrDocument,
                 title: "work title", id: "123", depositor: "user1", creator: "igor",
                 description: "a monster work", tags: ["moster", "mash"],
                 date_uploaded: DateTime.now, collection?: false, generic_work?: true,
                 hydra_model: "GenericWork", title_or_label: "A monster hit"
                )
    end

    before do
      allow(generic_work).to receive(:title_or_label).and_return(generic_work.title)
      allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      allow(view).to receive(:generic_work).and_return(generic_work)
      allow(view).to receive(:search_session).and_return({})
      allow(view).to receive(:current_search_session).and_return(nil)
    end

    it "draws the metadata fields for a work" do
      expect(view).to receive(:render_thumbnail_tag)
      render
      expect(rendered).to have_content 'work title'
      expect(rendered).to have_link("work title", sufia.generic_work_path(generic_work))
      expect(rendered).to have_content 'igor'
    end
  end
end
