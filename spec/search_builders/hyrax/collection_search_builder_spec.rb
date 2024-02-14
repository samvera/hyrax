# frozen_string_literal: true
RSpec.describe Hyrax::CollectionSearchBuilder do
  subject(:builder) { described_class.new(scope).with_access(access) }
  let(:access) { :read }
  let(:user) { FactoryBot.create(:user) }
  let(:scope) { FakeSearchBuilderScope.new(current_user: user) }

  describe '#sort_field' do
    its(:sort_field) { is_expected.to eq('title_si') }
  end

  describe '#models' do
    its(:models) do
      is_expected.to match_array(Hyrax::ModelRegistry.collection_classes)
    end

    context 'when collection class is not ::Collection' do
      before { allow(Hyrax.config).to receive(:collection_model).and_return('Hyrax::PcdmCollection') }
      its(:models) do
        is_expected
          .to contain_exactly(*[::Collection, Hyrax::PcdmCollection].uniq)
      end
    end
  end

  describe '#discovery_permissions' do
    context 'when access is read' do
      let(:access) { :read }

      its(:discovery_permissions) { is_expected.to eq %w[edit read] }
    end

    context 'when access is edit' do
      let(:access) { :edit }

      its(:discovery_permissions) { is_expected.to eq %w[edit] }
    end

    context 'when access is deposit' do
      let(:access) { :deposit }

      its(:discovery_permissions) { is_expected.to eq %w[deposit] }
    end
  end

  describe '#gated_discovery_filters' do
    subject { builder.gated_discovery_filters(access, ::Ability.new(user)) }

    context 'when access is :deposit' do
      let(:access) { "deposit" }
      let(:access_grant) do
        { agent_type:,
          agent_id: user.user_key,
          access: Hyrax::PermissionTemplateAccess::DEPOSIT}
      end
      let!(:collection) do
        valkyrie_create(:hyrax_collection, user: user, access_grants: [access_grant])
      end

      context 'and user has access' do
        let(:agent_type) { Hyrax::PermissionTemplateAccess::USER }

        it { is_expected.to eq ["{!terms f=id}#{collection.id}"] }
      end

      context 'and group has access' do
        let(:agent_type) { Hyrax::PermissionTemplateAccess::GROUP }

        it { is_expected.to eq ["{!terms f=id}#{collection.id}"] }
      end

      context "and user has no access" do
        let(:collection) do
          valkyrie_create(:hyrax_collection, :with_permission_template)
        end

        it { is_expected.to eq ["{!terms f=id}"] }
      end
    end
  end

  describe '#add_sorting_to_solr' do
    let(:builder_2) { described_class.new(scope).with(blacklight_params) }
    let(:blacklight_params) do
      { "sort" => "system_create_dtsi desc", "per_page" => "50", "locale" => "en" }
    end
    let(:solr_parameters) { {} }

    before { builder_2.add_sorting_to_solr(solr_parameters) }

    it 'sets the solr paramters for sorting correctly' do
      expect(solr_parameters[:sort]).to eq('system_create_dtsi desc')
    end
  end
end
