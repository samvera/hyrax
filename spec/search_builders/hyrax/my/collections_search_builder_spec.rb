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

    it do
      is_expected.to contain_exactly(AdminSet,
                                     Hyrax::AdministrativeSet,
                                     Hyrax.config.collection_class)
    end

    context 'when collection class is something other than ::Collection' do
      before { allow(Hyrax.config).to receive(:collection_model).and_return('Hyrax::PcdmCollection') }
      it do
        is_expected.to contain_exactly(AdminSet,
                                       Hyrax::AdministrativeSet,
                                       ::Collection,
                                       Hyrax::PcdmCollection)
      end
    end
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
