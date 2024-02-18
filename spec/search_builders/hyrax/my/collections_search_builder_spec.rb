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

  describe '#models' do
    subject { builder.models }

    it do
      is_expected.to match_array(Hyrax::ModelRegistry.admin_set_classes + Hyrax::ModelRegistry.collection_classes)
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
                                      "OR (_query_:\"{!terms f=has_model_ssim}#{Hyrax::ModelRegistry.admin_set_rdf_representations.join(',')}\" " \
                                      "AND _query_:\"{!terms f=creator_ssim}#{user.user_key}\"))"]
    end
  end
end
