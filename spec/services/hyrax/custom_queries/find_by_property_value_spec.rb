# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::FindByPropertyValue, :clean_repo do
  subject(:query_handler) { described_class.new(query_service: Hyrax.query_service) }

  let(:resources) { [resource1, resource2, resource3] }
  # Title contains quotes and special characters to test string escaping
  let(:resource1) { FactoryBot.valkyrie_create(:hyrax_work, title: '"Resource One!"', depositor: user1) }
  let(:resource2) { FactoryBot.valkyrie_create(:hyrax_work, title: 'Resource Two', depositor: user2) }
  let(:resource3) { FactoryBot.valkyrie_create(:hyrax_work, title: 'Resource Three', depositor: user1) }
  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }

  describe '#find_ids_by_property_pairs' do
    it 'returns ids matching the properties' do
      expect(query_handler.find_ids_by_property_pairs(pairs: { depositor: user1.to_s })).to be_empty
      resources
      expect(query_handler.find_ids_by_property_pairs(pairs: { depositor: user1.to_s })).to contain_exactly(resource1.id, resource3.id)
      expect(query_handler.find_ids_by_property_pairs(pairs: { title: '"Resource One!"', depositor: user1.to_s },
                                                      field_types: {'title': :stored_searchable})).to contain_exactly(resource1.id)
      expect(query_handler.find_ids_by_property_pairs(pairs: { title: '"Resource One!"', depositor: user2.to_s },
                                                      field_types: {'title': :stored_searchable})).to be_empty
    end
  end

  describe '#find_many_by_property_pairs' do
    it 'returns resources matching the properties' do
      expect(query_handler.find_many_by_property_pairs(pairs: { depositor: user1.to_s })).to be_empty
      resources
      expect(query_handler.find_many_by_property_pairs(pairs: { depositor: user1.to_s })).to contain_exactly(resource1, resource3)
      expect(query_handler.find_many_by_property_pairs(pairs: { title: '"Resource One!"', depositor: user1.to_s },
                                                      field_types: {'title': :stored_searchable})).to contain_exactly(resource1)
      expect(query_handler.find_many_by_property_pairs(pairs: { title: '"Resource One!"', depositor: user2.to_s },
                                                      field_types: {'title': :stored_searchable})).to be_empty
    end
  end

  describe '#find_many_by_property_value' do
    it 'returns resources matching the property value' do
      expect(query_handler.find_many_by_property_value(property: 'depositor', value: user1.to_s)).to be_empty
      resources
      expect(query_handler.find_many_by_property_value(property: 'depositor', value: user1.to_s)).to contain_exactly(resource1, resource3)
      expect(query_handler.find_many_by_property_value(property: 'title',
                                                  value: '"Resource One!"',
                                                  field_type: :stored_searchable)).to contain_exactly(resource1)
    end
  end

  describe '#find_by_property_value' do
    it 'returns a single resource matching the property value' do
      expect(query_handler.find_by_property_value(property: 'depositor', value: user1.to_s)).to be_nil
      resources
      expect(query_handler.find_by_property_value(property: 'depositor', value: user1.to_s)).to eq resource1
      expect(query_handler.find_by_property_value(property: 'title',
                                                  value: '"Resource One!"',
                                                  field_type: :stored_searchable)).to eq resource1
    end
  end
end
