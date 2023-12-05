# frozen_string_literal: true
RSpec.describe Hyrax::My::FindWorksSearchBuilder do
  let(:controller) { Qa::TermsController.new }
  let(:user) { create(:user) }
  let(:ability) { instance_double(Ability, admin?: false, user_groups: [], current_user: user) }
  let(:q) { "foo" }
  let(:params) { ActionController::Parameters.new(q: q, id: work.id, user: user.email, controller: "qa/terms", action: "search", vocab: "find_works") }

  let(:context) do
    FakeSearchBuilderScope.new(current_ability: ability,
                               current_user: user,
                               params: params)
  end
  let!(:work) { create(:generic_work, :public, title: ['foo'], user: user) }

  let(:builder) { described_class.new(context) }
  let(:solr_params) { Blacklight::Solr::Request.new }

  describe "#filter_on_title" do
    subject { builder.filter_on_title(solr_params) }

    it "is successful" do
      subject
      expect(solr_params[:fq]).to eq [ActiveFedora::SolrQueryBuilder.construct_query(title_tesim: q)]
    end
  end

  describe "#show_only_other_works" do
    subject { builder.show_only_other_works(solr_params) }

    it "is successful" do
      subject
      expect(solr_params[:fq]).to eq ["-" + Hyrax::SolrQueryService.new.with_ids(ids: [work.id]).build]
    end
  end

  describe "#show_only_works_not_child" do
    subject { builder.show_only_works_not_child(solr_params) }

    it "is successful" do
      subject
      ids = Hyrax::SolrService.query("{!field f=id}#{work.id}", fl: "member_ids_ssim").flat_map { |x| x.fetch("member_ids_ssim", []) }
      expect(solr_params[:fq]).to eq ["-" + Hyrax::SolrQueryService.new.with_ids(ids: [ids]).build]
    end

    it "is successful old way" do
      subject
      ids = Hyrax::SolrService.query("{!field f=id}#{work.id}", fl: "member_ids_ssim").flat_map { |x| x.fetch("member_ids_ssim", []) }
      expect(solr_params[:fq]).to eq ["-" + Hyrax::SolrQueryBuilderService.construct_query_for_ids([ids])]
      expect(ids.reject(&:blank?).empty?).to eq(false)
    end

    it "is successful new same code way" do
      subject
      ids = Hyrax::SolrService.query("{!field f=id}#{work.id}", fl: "member_ids_ssim").flat_map { |x| x.fetch("member_ids_ssim", []) }
      ids = [ids]
      expect(ids.to_s).to eq("false")

      # rubocop:disable Style/IfUnlessModifier
      if ids.reject(&:blank?).empty?
        expect(ids.to_s).to eq("false")
      end
      if Hyrax::SolrQueryBuilderService.construct_query_for_ids([ids]) == "id:NEVER_USE_THIS_ID"
        # if this is true that means he orininal test is bad.
        expect(true).to eq(false)
      end
      expect(solr_params[:fq]).to eq ["-" + Hyrax::SolrQueryService.new.with_ids(ids: ids).build]
    end
    it "is successful the real test" do
      subject
      ids = Hyrax::SolrService.query("{!field f=id}#{work.id}", fl: "member_ids_ssim").flat_map { |x| x.fetch("member_ids_ssim", []) }
      expect(solr_params[:fq]).to eq ["-" + "id:NEVER_USE_THIS_ID"]
    end
  end

  describe "#show_only_works_not_parent" do
    subject { builder.show_only_works_not_parent(solr_params) }

    it "is successful" do
      subject
      expect(solr_params[:fq]).to eq ["-" + ActiveFedora::SolrQueryBuilder.construct_query(member_ids_ssim: work.id)]
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
