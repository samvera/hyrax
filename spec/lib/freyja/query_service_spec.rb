# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'
require 'migrate_adapter/metadata_adapter'

RSpec.describe Freyja::QueryService, :clean_repo do
  let(:adapter) { Freyja::MetadataAdapter.new }

  context "items in postgres only" do
    it_behaves_like "a Valkyrie query provider" do
      let(:query_service) {
        Freyja::QueryService.new(
          Valkyrie::Persistence::Postgres::QueryService.new(adapter: adapter,
            resource_factory: adapter.resource_factory),
          Hyrax.query_service)
      }
    end
  end

  context "items in wings only" do
    it_behaves_like "a Valkyrie query provider" do
      let(:persister) { Wings::Valkyrie::Persister.new(adapter: adapter) }
      let(:query_service) {
        Freyja::QueryService.new(
          Valkyrie::Persistence::Postgres::QueryService.new(adapter: adapter,
                                                            resource_factory: adapter.resource_factory),
          Hyrax.query_service)
      }
    end

    context "after persisting with migrate adapter"
    # adapter.persister.save first, should not call the wings querey service at all

    context "after removing the item from fedora"
  end

  context "items in both wings and postgres"

  context "it supports custom queries"
  # app/services/hyrax/custom_queries/.rb
end
