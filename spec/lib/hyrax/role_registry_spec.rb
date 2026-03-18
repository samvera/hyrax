# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::RoleRegistry do
  let(:role_registry) { described_class.new }

  describe '#role_names (without adding roles)' do
    subject { role_registry.role_names }

    it { is_expected.to eq(['approving', 'depositing', 'managing']) }
  end

  describe '#registered_role?' do
    subject { role_registry.registered_role?(name: name) }

    describe 'for already registered name' do
      let(:name) { described_class::MANAGING }

      it { is_expected.to be_truthy }
    end
    describe 'for non-registered name' do
      let(:name) { 'gong_farming' }

      it { is_expected.to be_falsey }
    end
  end

  describe '#add' do
    subject { role_registry.add(name: 'captaining', description: 'Grants captain duties') }

    it 'includes those added via #add' do
      expect { subject }.to change { role_registry.role_names }
        .from(['approving', 'depositing', 'managing']).to(['approving', 'captaining', 'depositing', 'managing'])
    end
  end

  describe '#persist_registered_roles!' do
    it 'creates Sipity::Role records for each role_name' do
      # Use unique test-only role names so the assertion is independent of
      # whether the default roles (approving/depositing/managing) already exist
      # from prior specs that call persist_registered_roles! or WorkflowImporter.
      custom_registry = described_class.new
      custom_registry.add(name: 'test_only_alpha', description: 'Test only role alpha')
      custom_registry.add(name: 'test_only_beta', description: 'Test only role beta')

      expect { custom_registry.persist_registered_roles! }
        .to change { Sipity::Role.where(name: %w[test_only_alpha test_only_beta]).count }
        .by(2)
    end
  end
end
