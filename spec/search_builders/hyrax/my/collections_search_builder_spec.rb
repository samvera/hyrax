# frozen_string_literal: true
RSpec.describe Hyrax::My::CollectionsSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability,
           current_user: user)
  end
  let(:ability) do
    ::Ability.new(user)
  end
  let(:user) { create(:user) }
  let(:builder) { described_class.new(context) }

  describe '#models' do
    subject { builder.models }

    it { is_expected.to eq([AdminSet, Collection]) }
  end

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include :show_only_collections_deposited_by_current_user }
  end

  describe "#show_only_collections_deposited_by_current_user" do
    subject { builder.show_only_collections_deposited_by_current_user(solr_params) }

    let(:solr_params) { Blacklight::Solr::Request.new }

    it "has filter that excludes depositor" do
      subject
      expect(solr_params[:fq]).to eq ["(_query_:\"{!raw f=depositor_ssim}#{user.user_key}\" OR (_query_:\"{!raw f=has_model_ssim}AdminSet\" AND _query_:\"{!raw f=creator_ssim}#{user.user_key}\"))"]
    end
  end
end
