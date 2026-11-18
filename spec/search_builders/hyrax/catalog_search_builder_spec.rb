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

    context 'when the user is a viewer on a private collection', :clean_repo do
      let(:user) { create(:user) }
      let(:viewer_grant) do
        { agent_type: Hyrax::PermissionTemplateAccess::USER, agent_id: user.user_key,
          access: Hyrax::PermissionTemplateAccess::VIEW }
      end
      let!(:shared_collection) { FactoryBot.valkyrie_create(:hyrax_collection, access_grants: [viewer_grant]) }
      let!(:other_collection) { FactoryBot.valkyrie_create(:hyrax_collection) }

      it "includes the shared collection and not the other private one" do
        subject
        expect(solr_params['f.member_of_collection_ids_ssim.facet.matches']).to eq "^#{shared_collection.id}$"
      end
    end

    it "includes an empty regex when user doesn't have access to view any collections", :clean_repo do
      subject
      expect(solr_params['f.member_of_collection_ids_ssim.facet.matches']).to eq '^$'
    end

    context 'when an anonymous visitor can see a collection by its visibility', :clean_repo do
      let(:ability) { Ability.new(nil) }
      let!(:public_collection) { FactoryBot.valkyrie_create(:hyrax_collection, :public) }
      let!(:private_collection) { FactoryBot.valkyrie_create(:hyrax_collection) }

      it "includes the public collection and not the private one" do
        subject
        facet_matches = solr_params['f.member_of_collection_ids_ssim.facet.matches']
        expect(facet_matches).to include "^#{public_collection.id}$"
        expect(facet_matches).not_to include private_collection.id.to_s
      end

      it "leaves out collections an application narrows out of visible_collections_query" do
        allow(builder).to receive(:visible_collections_query)
          .and_return(Hyrax::SolrQueryService.new(query: ["-#{Hyrax.config.id_field}:#{public_collection.id}"]))

        subject
        expect(solr_params['f.member_of_collection_ids_ssim.facet.matches']).to eq '^$'
      end
    end
  end
end
