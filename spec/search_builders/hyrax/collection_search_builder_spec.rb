# frozen_string_literal: true
RSpec.describe Hyrax::CollectionSearchBuilder do
  let(:scope) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:builder) { described_class.new(scope).with_access(access) }

  describe '#sort_field' do
    let(:access) { :read }

    subject { builder.sort_field }

    it { is_expected.to eq('title_si') }
  end

  describe '#models' do
    let(:access) { :read }

    subject { builder.models }

    it { is_expected.to eq([Collection]) }
  end

  describe '#discovery_permissions' do
    subject { builder.discovery_permissions }

    context 'when access is read' do
      let(:access) { :read }

      it { is_expected.to eq %w[edit read] }
    end

    context 'when access is edit' do
      let(:access) { :edit }

      it { is_expected.to eq %w[edit] }
    end

    context 'when access is deposit' do
      let(:access) { :deposit }

      it { is_expected.to eq %w[deposit] }
    end
  end

  describe '#gated_discovery_filters' do
    subject { builder.gated_discovery_filters(access, ability) }

    context 'when access is :deposit' do
      let(:access) { "deposit" }
      let!(:collection) { create(:collection_lw, with_permission_template: attributes) }

      context 'and user has access' do
        let(:attributes) { { deposit_users: [user.user_key] } }

        it { is_expected.to eq ["{!terms f=id}#{collection.id}"] }
      end

      context 'and group has access' do
        let(:attributes) { { deposit_groups: ['registered'] } }

        it { is_expected.to eq ["{!terms f=id}#{collection.id}"] }
      end

      context "and user has no access" do
        let(:attributes) { true }

        it { is_expected.to eq ["{!terms f=id}"] }
      end
    end
  end
end
