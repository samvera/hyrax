# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'
require 'frigg/metadata_adapter'

RSpec.describe Frigg::QueryService, :clean_repo do
  let(:adapter) { Frigg::MetadataAdapter.new }

  xcontext "items in postgres only" do
    it_behaves_like "a Valkyrie query provider" do
      let(:query_service) do
        Frigg::QueryService.new(
          Valkyrie::Persistence::Fedora::QueryService.new(adapter: self),
          Valkyrie::MetadataAdapter.adapters[:wings_adapter].query_service
        )
      end
    end
  end

  xcontext "items in wings only" do
    it_behaves_like "a Valkyrie query provider" do
      let(:persister) { Wings::Valkyrie::Persister.new(adapter: adapter) }
      let(:query_service) do
        Frigg::QueryService.new(
          Valkyrie::Persistence::Fedora::QueryService.new(adapter: self),
          Valkyrie::MetadataAdapter.adapters[:wings_adapter].query_service
        )
      end
    end
  end

  xcontext "items in both should be found from postgres only" do
    it_behaves_like "a Valkyrie query provider" do
      let(:pg_persister) { Valkyrie::Persistence::Postgres::Persister.new(adapter: adapter) }
      let(:wings_persister) { Wings::Valkyrie::Persister.new(adapter: adapter) }
      let(:persister) { Valkyrie::Persistence::CompositePersister.new(pg_persister, wings_persister) }
      let(:query_service) do
        Frigg::QueryService.new(
          Valkyrie::Persistence::Fedora::QueryService.new(adapter: self),
          Valkyrie::MetadataAdapter.adapters[:wings_adapter].query_service
        )
      end
      let(:before_find_by) { -> { expect(Hyrax.query_service).not_to receive(:find_by) } }
      let(:before_find_by_alternate_identifier) { -> { expect(Hyrax.query_service).not_to receive(:find_by_alternate_identifier) } }
    end
  end
  context "it supports custom queries"
  # app/services/hyrax/custom_queries/.rb
end
