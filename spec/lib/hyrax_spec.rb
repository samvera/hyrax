# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax do
  describe '.logger' do
    it 'is a Logger' do
      expect(described_class.logger).to respond_to :log
    end
  end

  describe 'default_admin_set' do
    it 'returns true' do
      default_admin_set = described_class.default_admin_set
      expect(default_admin_set).to be_kind_of Hyrax::AdministrativeSet
      expect(default_admin_set.alternate_ids).to eq [Hyrax::AdminSetCreateService::DEFAULT_ID]
    end
  end

  describe 'default_admin_set_id?' do
    context 'when id is for the default admin set' do
      let(:admin_set) { FactoryBot.valkyrie_create(:default_hyrax_admin_set) }
      it 'returns true' do
        expect(described_class.default_admin_set_id?(id: admin_set.id)).to eq true
      end
    end

    context 'when id is NOT for the default admin set' do
      let(:admin_set) { FactoryBot.valkyrie_create(:hyrax_admin_set) }
      it 'returns true' do
        expect(described_class.default_admin_set_id?(id: admin_set.id)).to eq false
      end
    end
  end
end
