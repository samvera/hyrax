describe Sufia::MySharesSearchBuilder do
  let(:me) { create(:user) }
  let(:config) { CatalogController.blacklight_config }
  let(:scope) do
    double('The scope',
           blacklight_config: config,
           params: {},
           current_ability: Ability.new(me),
           current_user: me)
  end
  let(:builder) { described_class.new(scope) }

  let(:solr_params) { { q: user_query } }

  before do
    allow(builder).to receive(:gated_discovery_filters).and_return(["access_filter1", "access_filter2"])
    allow(ActiveFedora::SolrQueryBuilder).to receive(:construct_query_for_rel)
      .with(depositor: me.user_key)
      .and_return("depositor")
  end

  subject { builder.to_hash['fq'] }

  it "filters things we have access to in which we are not the depositor" do
    expect(subject).to eq ["access_filter1 OR access_filter2",
                           "{!terms f=has_model_ssim}GenericWork,Collection",
                           "-depositor",
                           "-suppressed_bsi:true"]
  end

  describe "mediated deposit" do
    let(:user_query) { nil }

    context "with suppressed items" do
      it "does includes suppressed switch" do
        builder.show_only_shared_files(solr_params)
        expect(solr_params[:fq]).to eq ["-depositor", "-suppressed_bsi:true"]
      end
    end
  end
end
