# frozen_string_literal: true
RSpec.describe Hyrax::My::CollectionsSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability,
           current_user: user,
           search_state_class: nil)
  end
  let(:ability) do
    ::Ability.new(user)
  end
  let(:user) { create(:user) }
  let(:builder) { described_class.new(context) }
  let(:admin_klass) { Hyrax.config.disable_wings ? Hyrax::AdministrativeSet : AdminSet }
  let(:expected_klasses) do
    if Hyrax.config.disable_wings
      [AdminSet, Hyrax::AdministrativeSet, Hyrax::PcdmCollection]
    else
      [AdminSet, Hyrax::AdministrativeSet, ::Collection, Hyrax::PcdmCollection]
    end
  end

  describe '#models' do
    subject { builder.models }

    it do
      is_expected.to include(AdminSet,
                             Hyrax::AdministrativeSet,
                             Hyrax.config.collection_class)
    end

    context 'when collection class is something other than ::Collection' do
      before { allow(Hyrax.config).to receive(:collection_model).and_return('Hyrax::PcdmCollection') }
      it { is_expected.to contain_exactly(*expected_klasses) }
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
      expect(solr_params[:fq]).to eq ["(_query_:\"{!terms f=depositor_ssim}#{user.user_key}\" " \
                                      "OR (_query_:\"{!terms f=has_model_ssim}#{admin_klass}\" " \
                                      "AND _query_:\"{!terms f=creator_ssim}#{user.user_key}\"))"]
    end
  end
end
