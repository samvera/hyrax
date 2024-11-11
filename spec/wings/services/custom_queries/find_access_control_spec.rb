# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'
require 'wings/services/custom_queries/find_access_control'

RSpec.describe Wings::CustomQueries::FindAccessControl, :active_fedora do
  subject(:query_handler) { described_class.new(query_service: query_service) }
  let(:adapter)           { Valkyrie::MetadataAdapter.find(:wings_adapter) }
  let(:persister)         { adapter.persister }
  let(:query_service)     { adapter.query_service }

  describe '#find_access_control' do
    context 'for missing object' do
      let(:resource) { Hyrax::Resource.new }

      it 'raises ObjectNotFoundError' do
        expect { query_handler.find_access_control_for(resource: resource) }
          .to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'when the resource has been created via Wings' do
      let(:resource) { persister.save(resource: Hyrax::Resource.new) }

      it 'finds an empty acl' do
        expect(query_handler.find_access_control_for(resource: resource))
          .to have_attributes(permissions: be_empty)
      end
    end
  end
end
