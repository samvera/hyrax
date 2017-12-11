RSpec.describe Hyrax::My::FindWorksSearchBuilder do
  let(:controller) { Qa::TermsController.new }
  let(:user) { create(:user) }
  let(:ability) { instance_double(Ability, admin?: false, user_groups: [], current_user: user) }
  let(:q) { "foo" }
  let(:params) { ActionController::Parameters.new(q: q, id: work.id.to_s, user: user.email, controller: "qa/terms", action: "search", vocab: "find_works") }

  let(:context) do
    double(current_ability: ability,
           current_user: user,
           params: params)
  end
  let!(:work) { create_for_repository(:work, :public, title: ['foo'], user: user) }

  let(:builder) { described_class.new(context) }
  let(:solr_params) { Blacklight::Solr::Request.new }

  describe "#filter_on_title" do
    subject { builder.filter_on_title(solr_params) }

    it "is successful" do
      subject
      expect(solr_params[:fq]).to eq ["_query_:\"{!field f=title_tesim}foo\""]
    end
  end

  describe "#show_only_other_works" do
    subject { builder.show_only_other_works(solr_params) }

    it "is successful" do
      subject
      expect(solr_params[:fq]).to eq ["-{!field f=id}#{work.id}"]
    end
  end

  describe "#show_only_works_not_child" do
    subject { builder.show_only_works_not_child(solr_params) }

    let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr).connection }
    let!(:work) { create_for_repository(:work_with_one_child, :public, title: ['foo'], user: user) }

    it "is successful" do
      subject
      results = solr.get('select', params: { q: "{!field f=id}#{work.id}",
                                             fl: "member_ids_ssim",
                                             qt: 'standard' })
      ids = results['response']['docs'].flat_map { |x| x.fetch("member_ids_ssim", []) }
      expect(solr_params[:fq]).to eq ["-{!terms f=id}#{ids.first}"]
    end
  end

  describe "#show_only_works_not_parent" do
    subject { builder.show_only_works_not_parent(solr_params) }

    it "is successful" do
      subject
      expect(solr_params[:fq]).to eq ["-_query_:\"{!field f=member_ids_ssim}id-#{work.id}\""]
    end
  end

  describe "#only_works?" do
    subject { builder.only_works? }

    it "is successful" do
      subject
      expect(subject). to eq true
    end
  end
end
