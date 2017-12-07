RSpec.describe Hyrax::Dashboard::WorksController, type: :controller do
  describe "#search_builder_class" do
    subject { controller.search_builder_class }

    it { is_expected.to eq Hyrax::WorksSearchBuilder }
  end

  describe "#search_facet_path" do
    subject { controller.send(:search_facet_path, id: 'keyword_ssim') }

    it { is_expected.to eq "/dashboard/works/facet/keyword_ssim?locale=en" }
  end
end
