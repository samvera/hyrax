# frozen_string_literal: true
module Sipity
  RSpec.describe Entity, type: :model, valkyrie_adapter: :test_adapter do
    subject(:entity) { described_class.new }

    describe 'database configuration' do
      subject { described_class }

      its(:column_names) { is_expected.to include("proxy_for_global_id") }
      its(:column_names) { is_expected.to include("workflow_id") }
      its(:column_names) { is_expected.to include("workflow_state_id") }
    end

    describe 'delegations' do
      it { is_expected.to delegate_method(:workflow_state_name).to(:workflow_state).as(:name) }
      it { is_expected.to delegate_method(:workflow_name).to(:workflow).as(:name) }
    end

    describe '#proxy_for' do
      subject(:entity) { described_class.new(proxy_for_global_id: Hyrax::GlobalID(work).to_s) }
      let(:work)       { valkyrie_create(:hyrax_work) }

      it 'will retrieve based on a GlobalID of the object' do
        expect(entity.proxy_for).to eq(work)
      end
    end
  end
end
