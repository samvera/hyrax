# frozen_string_literal: true
RSpec.describe Hyrax::CompoundWorkPickerBuilder do
  let(:user) { create(:user) }
  let(:ability) { instance_double(Ability, admin?: false, user_groups: [], current_user: user) }
  let(:params) do
    ActionController::Parameters.new(q: q, user: user.email,
                                     controller: "qa/terms", action: "search", vocab: "compound_works")
  end
  let(:context) do
    FakeSearchBuilderScope.new(current_ability: ability, current_user: user, params: params)
  end
  let(:builder) { described_class.new(context) }
  let(:solr_params) { Blacklight::Solr::Request.new }

  describe "::default_processor_chain" do
    it "appends the broad-term/partial-title filter" do
      expect(described_class.default_processor_chain).to include(:filter_on_any_term_or_partial_title)
    end
  end

  describe "#only_works?" do
    let(:q) { "foo" }

    it "restricts to works" do
      expect(builder.only_works?).to be true
    end
  end

  describe "#filter_on_any_term_or_partial_title" do
    subject { builder.filter_on_any_term_or_partial_title(solr_params) }

    context "with a single-token term" do
      let(:q) { "journal" }

      it "ORs a multi-field match with a prefix-title match and uses the lucene parser" do
        subject
        expect(solr_params[:q]).to eq(
          "title_tesim:(journal) OR description_tesim:(journal) OR " \
          "creator_tesim:(journal) OR keyword_tesim:(journal) OR " \
          "title_tesim:(journal*)"
        )
        expect(solr_params[:defType]).to eq("lucene")
      end
    end

    context "with a multi-token term" do
      let(:q) { "journal studies" }

      it "ANDs prefix wildcards across the title tokens" do
        subject
        expect(solr_params[:q]).to end_with("title_tesim:(journal* AND studies*)")
      end
    end

    context "with a blank term" do
      let(:q) { "" }

      it "leaves the solr parameters untouched" do
        subject
        expect(solr_params[:q]).to be_nil
        expect(solr_params[:defType]).to be_nil
      end
    end

    context "with Solr special characters in the term" do
      let(:q) { "a:b" }

      it "escapes the special characters" do
        subject
        expect(solr_params[:q]).to include('title_tesim:(a\\:b)')
      end
    end
  end
end
