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
    subject { role_registry.persist_registered_roles! }

    it 'creates Sipity::Role records for each role_name' do
      expect { subject }.to change { Sipity::Role.count }.by(role_registry.role_names.count)
    end
  end
end
