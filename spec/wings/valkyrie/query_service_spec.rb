# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'

RSpec.describe Wings::Valkyrie::QueryService do
  before do
    class Book < ActiveFedora::Base
      property :title, predicate: ::RDF::Vocab::DC.title, multiple: true
    end
  end

  after do
    Object.send(:remove_const, :Book)
  end

  subject(:query_service) { described_class.new(adapter: adapter) }
  let(:adapter) { Wings::Valkyrie::MetadataAdapter.new }
  let(:persister) { Wings::Valkyrie::Persister.new(adapter: adapter) }
  let(:af_resource_class) { Book }
  let(:resource_class) { Wings::ModelTransformer.to_valkyrie_resource_class(klass: af_resource_class) }
  let(:resource) { resource_class.new(title: ['Foo']) }

  # it_behaves_like "a Valkyrie query provider"

  it 'responds to expected methods' do
    expect(subject).to respond_to(:find_by).with_keywords(:id)
    expect(subject).to respond_to(:resource_factory)
  end

  describe ".find_by" do
    it "returns a resource by id or string representation of an id" do
      book = persister.save(resource: resource)

      found = query_service.find_by(id: book.id)
      expect(found.id).to eq book.id
      # expect(found).to be_persisted

      found = query_service.find_by(id: book.id.to_s)
      expect(found.id).to eq book.id
      # expect(found).to be_persisted
    end

    it "returns a Valkyrie::Persistence::ObjectNotFoundError for a non-found ID" do
      expect { query_service.find_by(id: ::Valkyrie::ID.new("123123123")) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'raises an error if the id is not a Valkyrie::ID or a string' do
      expect { query_service.find_by(id: 123) }.to raise_error ArgumentError
    end
  end

  describe ".register_query_handler" do
    before do
      class QueryHandler
        def self.queries
          [:find_by_user_id]
        end

        attr_reader :query_service
        def initialize(query_service:)
          @query_service = query_service
        end

        def find_by_user_id
          1
        end
      end
    end

    after do
      Object.send(:remove_const, :QueryHandler)
    end

    it "can register a query handler" do
      query_service.custom_queries.register_query_handler(QueryHandler)
      expect(query_service.custom_queries).to respond_to :find_by_user_id
      expect(query_service.custom_queries.find_by_user_id).to eq 1
    end
  end
end
