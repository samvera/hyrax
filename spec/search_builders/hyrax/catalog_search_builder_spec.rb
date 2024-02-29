# frozen_string_literal: true
RSpec.describe Hyrax::CatalogSearchBuilder do
  let(:context) { FakeSearchBuilderScope.new }
  let(:builder) { described_class.new(context).with(blacklight_params) }
  let(:solr_params) { Blacklight::Solr::Request.new }
  let(:blacklight_params) { { q: user_query, search_field: 'all_fields' } }
  let(:user_query) { "find me" }

  describe "#show_works_or_works_that_contain_files" do
    subject { builder.show_works_or_works_that_contain_files(solr_params) }

    context "with a user query" do
      it "creates a valid solr join for works and files" do
        subject
        expect(solr_params[:user_query]).to eq user_query
        expect(solr_params[:q]).to eq '{!lucene}_query_:"{!dismax v=$user_query}" _query_:"{!join from=id to=member_ids_ssim}{!lucene q.op=AND}has_model_ssim:*FileSet{!dismax v=$user_query}"'
      end
    end

    context "without a user query" do
      let(:blacklight_params) { {} }

      it "does not modify the query" do
        subject
        expect(solr_params[:user_query]).to be_nil
        expect(solr_params[:q]).to be_nil
      end
    end

    context "when doing a fielded search" do
      let(:blacklight_params) { { q: user_query, search_field: 'depositor' } }
      # Blacklight sets up these values when we've done a fielded search.
      # Here we're ensuring they aren't wiped out
      let(:solr_params) { Blacklight::Solr::Request.new("q" => "{!qf=depositor_ssim pf=depositor_ssim}\"#{user_query}\"") }

      it "does not modify the query" do
        subject
        expect(solr_params[:user_query]).to be_nil
        expect(solr_params[:q]).to eq '{!qf=depositor_ssim pf=depositor_ssim}"find me"'
      end
    end
  end

  describe "#show_only_active_records" do
    subject { builder.show_only_active_records(solr_params) }

    it "includes suppressed switch" do
      subject
      expect(solr_params[:fq]).to eq ["-suppressed_bsi:true"]
    end
  end

  describe "#filter_collection_facet_for_access" do
    let(:user) { build(:user) }
    let(:ability) { Ability.new(user) }
    let(:context) { FakeSearchBuilderScope.new(current_ability: ability) }

    subject { builder.filter_collection_facet_for_access(solr_params) }

    context 'with an admin' do
      let(:user) { build(:admin) }

      it "does nothing if user is an admin" do
        subject
        expect(solr_params['f.member_of_collection_ids_ssim.facet.matches']).to be_blank
      end
    end

    context 'when the user has view access to collections' do
      let(:collection_ids) { ['abcd12345', 'efgh67890'] }

      before do
        allow(Hyrax::Collections::PermissionsService).to receive(:collection_ids_for_view).with(ability: ability).and_return(collection_ids)
      end

      it "includes a regex of the ids of collections" do
        subject
        expect(solr_params['f.member_of_collection_ids_ssim.facet.matches']).to eq '^abcd12345$|^efgh67890$'
      end
    end

    it "includes an empty regex when user doesn't have access to view any collections" do
      subject
      expect(solr_params['f.member_of_collection_ids_ssim.facet.matches']).to eq '^$'
    end
  end
end
