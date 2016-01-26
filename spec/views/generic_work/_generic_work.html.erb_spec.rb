require 'spec_helper'

describe 'generic_works/_generic_work.html.erb', type: :view do
  context 'displaying a file_set' do
    let(:generic_work) do
      mock_model(SolrDocument,
                 title: "work title", id: "123", depositor: "user1", creator: "igor",
                 description: "a monster work", tags: ["moster", "mash"],
                 has_model_ssim: ['GenericWork'], itemtype: ['CreativeWork'],
                 date_uploaded: DateTime.now, collection?: false, generic_work?: true,
                 hydra_model: "GenericWork", title_or_label: "A monster hit"
                )
    end

    let(:blacklight_configuration_context) do
      Blacklight::Configuration::Context.new(controller)
    end

    before do
      allow(generic_work).to receive(:title_or_label).and_return(generic_work.title)
      allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
      allow(view).to receive(:generic_work).and_return(generic_work)
      allow(view).to receive(:generic_work_counter).and_return(0)
      allow(view).to receive(:search_session).and_return({})
      allow(view).to receive(:current_search_session).and_return(nil)
    end

    it "draws the metadata fields for a work" do
      expect(view).to receive(:render_thumbnail_tag)
      render
      expect(rendered).to have_content 'work title'
      expect(rendered).to have_link("work title", curation_concerns_generic_work_path(generic_work))
      expect(rendered).to have_content 'igor'
    end
  end
end
