# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::FindAccessControl do
  subject(:query_handler) { described_class.new(query_service: query_service) }
  let(:adapter)           { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:persister)         { adapter.persister }
  let(:query_service)     { adapter.query_service }

  describe '#find_access_control' do
    context 'for missing object' do
      let(:resource) { Valkyrie::Resource.new }

      it 'raises ObjectNotFoundError' do
        expect { query_handler.find_access_control_for(resource: resource) }
          .to raise_error { Valkyrie::Persistence::ObjectNotFoundError }
      end
    end

    context 'when an acl exists' do
      let(:acl)      { persister.save(resource: Hyrax::AccessControl.new(access_to: resource.id)) }
      let(:resource) { persister.save(resource: Hyrax::Resource.new) }

      before { acl } # ensure the acl gets saved

      it 'returns the acl' do
        expect(query_handler.find_access_control_for(resource: resource))
          .to eq acl
      end
    end

    context 'for another class purporting to provide access_to' do
      let(:malicious_acl) { malicious_acl_class }
      let(:resource)      { adapter.persister.save(resource: Hyrax::Resource.new) }

      let(:malicious_acl_class) do
        Class.new(Valkyrie::Resource) do
          attribute :access_to, Valkyrie::Types::ID
        end
      end

      it 'raises ObjectNotFoundError' do
        expect { query_handler.find_access_control_for(resource: resource) }
          .to raise_error { Valkyrie::Persistence::ObjectNotFoundError }
      end
    end
  end
end
