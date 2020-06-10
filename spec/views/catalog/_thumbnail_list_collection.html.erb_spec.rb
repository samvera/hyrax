# frozen_string_literal: true
RSpec.describe 'catalog/_thumbnail_list_collection.html.erb', type: :view do
  context "When the collection thumbnail is attached" do
    let(:attributes) do
      { id: "xxx",
        "has_model_ssim": ["Collection"],
        "title_tesim": ["Collection Title"],
        "description_tesim": ["Collection Description"],
        "system_modified_dtsi": 'date',
        "thumbnail_path_ss": '/xxx/yyy?file=thumbnail' }
    end
    let(:doc) { SolrDocument.new(attributes) }
    let(:current_ability) { Ability.new(build(:user)) }

    before do
      render 'catalog/thumbnail_list_collection', document: doc
    end

    it 'displays the collection thumbnail in the search results' do
      expect(rendered).to include '/xxx/yyy?file=thumbnail'
    end
  end

  context "When the collection thumbnail is not attached" do
    let(:attributes) do
      { id: "xxx",
        "has_model_ssim": ["Collection"],
        "title_tesim": ["Collection Title"],
        "description_tesim": ["Collection Description"],
        "system_modified_dtsi": 'date',
        "thumbnail_path_ss" => Hyrax::CollectionIndexer.thumbnail_path_service.default_image }
    end
    let(:doc) { SolrDocument.new(attributes) }
    let(:current_ability) { Ability.new(build(:user)) }

    before do
      render 'catalog/thumbnail_list_collection', document: doc
    end

    it 'displays the collection icon in the search results' do
      expect(rendered).to include '/assets/collection-'
    end
  end
end
