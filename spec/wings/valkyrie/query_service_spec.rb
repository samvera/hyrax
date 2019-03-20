# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'

RSpec.describe Wings::Valkyrie::QueryService do
  before do
    class Book < ActiveFedora::Base
      property :title, predicate: ::RDF::Vocab::DC.title, multiple: true
      property :a_member_of, predicate: ::RDF::URI.new('http://www.example.com/a_member_of'), multiple: true
      property :an_ordered_member_of, predicate: ::RDF::URI.new('http://www.example.com/an_ordered_member_of'), multiple: true
    end
    class Image < ActiveFedora::Base
      property :title, predicate: ::RDF::Vocab::DC.title, multiple: true
    end
  end

  after do
    Object.send(:remove_const, :Book)
    Object.send(:remove_const, :Image)
  end

  subject(:query_service) { described_class.new(adapter: adapter) }
  let(:adapter) { Wings::Valkyrie::MetadataAdapter.new }
  let(:persister) { Wings::Valkyrie::Persister.new(adapter: adapter) }
  let(:af_resource_class) { Book }
  let(:af_image_resource_class) { Image }
  let(:resource_class) { Wings::ModelTransformer.to_valkyrie_resource_class(klass: af_resource_class) }
  let(:image_resource_class) { Wings::ModelTransformer.to_valkyrie_resource_class(klass: af_image_resource_class) }
  let(:resource) { resource_class.new(title: ['Foo']) }

  # it_behaves_like "a Valkyrie query provider"

  it 'responds to expected methods' do
    expect(subject).to respond_to(:find_by).with_keywords(:id)
    expect(subject).to respond_to(:resource_factory)
    expect(subject).to respond_to(:find_all).with(0).arguments
    expect(subject).to respond_to(:find_all_of_model).with_keywords(:model)
    expect(subject).to respond_to(:find_many_by_ids).with_keywords(:ids)
    expect(subject).to respond_to(:find_by_alternate_identifier).with_keywords(:alternate_identifier)
    respond_to(:find_references_by).with_keywords(:resource, :property)
  end

  describe ".find_by" do
    it "returns a resource by id or string representation of an id" do
      book = persister.save(resource: resource)

      found = query_service.find_by(id: book.id)
      expect(found.id).to eq book.id
      expect(found).to be_persisted

      found = query_service.find_by(id: book.id.to_s)
      expect(found.id).to eq book.id
      expect(found).to be_persisted
    end

    it "returns a Valkyrie::Persistence::ObjectNotFoundError for a non-found ID" do
      expect { query_service.find_by(id: ::Valkyrie::ID.new("123123123")) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'raises an error if the id is not a Valkyrie::ID or a string' do
      expect { query_service.find_by(id: 123) }.to raise_error ArgumentError
    end
  end

  describe ".find_all", clean_repo: true do
    before do
      allow(Hyrax.config).to receive(:curation_concerns).and_return(Hyrax.config.curation_concerns.append(::Collection).append(af_resource_class))
    end

    it "returns all created resources and no access control objects" do
      work = create(:generic_work)
      resource1 = persister.save(resource: resource_class.new)
      resource2 = persister.save(resource: resource_class.new)

      expect(query_service.find_all.map(&:id)).to contain_exactly resource1.id, resource2.id, Valkyrie::ID.new(work.id)
    end

    it "returns an empty array if there are none" do
      expect(query_service.find_all.to_a).to eq []
    end
  end

  describe ".find_all_of_model", clean_repo: true do
    it "returns all of that model" do
      persister.save(resource: resource_class.new)
      resource2 = persister.save(resource: image_resource_class.new)

      expect(query_service.find_all_of_model(model: image_resource_class).map(&:id)).to contain_exactly resource2.id
    end

    it "returns an empty array if there are none" do
      persister.save(resource: resource_class.new)
      persister.save(resource: resource_class.new)

      expect(query_service.find_all_of_model(model: image_resource_class).to_a).to eq []
    end
  end

  describe ".find_by_alternate_identifier" do
    it "returns a resource by alternate identifier or string representation of an alternate identifier" do
      resource = resource_class.new
      resource.alternate_ids = [Valkyrie::ID.new('p9s0xfj')]
      resource = persister.save(resource: resource)

      found = query_service.find_by_alternate_identifier(alternate_identifier: resource.alternate_ids.first)
      expect(found.id).to eq resource.id
      expect(found).to be_persisted

      found = query_service.find_by_alternate_identifier(alternate_identifier: resource.alternate_ids.first.to_s)
      expect(found.id).to eq resource.id
      expect(found).to be_persisted
    end

    # Not a use case that Hyrax has; everything has to have an alternate_id
    #   We can't make this test pass because we can't persist an object without
    #   an alternate_id
    xit 'raises a Valkyrie::Persistence::ObjectNotFoundError when persisted objects do not have alternate_ids' do
      persister.save(resource: SecondResource.new)
      expect { query_service.find_by_alternate_identifier(alternate_identifier: Valkyrie::ID.new("123123123")) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end

    it "raises a Valkyrie::Persistence::ObjectNotFoundError for a non-found alternate identifier" do
      expect { query_service.find_by_alternate_identifier(alternate_identifier: Valkyrie::ID.new("123123123")) }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'raises an error if the alternate identifier is not a Valkyrie::ID or a string' do
      expect { query_service.find_by_alternate_identifier(alternate_identifier: 123) }.to raise_error ArgumentError
    end

    it 'can have multiple alternate identifiers' do
      resource = resource_class.new
      resource.alternate_ids = [Valkyrie::ID.new('p9s0xfj'), Valkyrie::ID.new('jks0xfj')]
      resource = persister.save(resource: resource)

      found = query_service.find_by_alternate_identifier(alternate_identifier: resource.alternate_ids.first)
      expect(found.id).to eq resource.id
      expect(found).to be_persisted

      found = query_service.find_by_alternate_identifier(alternate_identifier: resource.alternate_ids.last)
      expect(found.id).to eq resource.id
      expect(found).to be_persisted
    end
  end

  describe ".find_many_by_ids" do
    let!(:resource) { persister.save(resource: resource_class.new) }
    let!(:resource2) { persister.save(resource: resource_class.new) }
    let!(:resource3) { persister.save(resource: resource_class.new) }

    it "returns an array of resources by ids or string representation ids" do
      found = query_service.find_many_by_ids(ids: [resource.id, resource2.id])
      expect(found.map(&:id)).to contain_exactly resource.id, resource2.id

      found = query_service.find_many_by_ids(ids: [resource.id.to_s, resource2.id.to_s])
      expect(found.map(&:id)).to contain_exactly resource.id, resource2.id
    end

    it "returns a partial list for a non-found ID" do
      found = query_service.find_many_by_ids(ids: [resource.id, Valkyrie::ID.new("123123123")])
      expect(found.map(&:id)).to contain_exactly resource.id
    end

    it "returns an empty list if no ids were found" do
      found = query_service.find_many_by_ids(ids: [Valkyrie::ID.new("you-cannot-find-me"), Valkyrie::ID.new("123123123")])
      expect(found.map(&:id)).to eq []
    end

    it 'raises an error if any id is not a Valkyrie::ID or a string' do
      expect { query_service.find_many_by_ids(ids: [resource.id, 123]) }.to raise_error ArgumentError
    end

    it "removes duplicates" do
      found = query_service.find_many_by_ids(ids: [resource.id, resource2.id, resource.id])
      expect(found.map(&:id)).to contain_exactly resource.id, resource2.id
    end
  end

  describe ".find_references_by" do
    context "when the property is unordered" do
      it "returns all references given in a property" do
        parent = persister.save(resource: resource_class.new(title: ['Parent']))
        parent2 = persister.save(resource: resource_class.new(title: ['Parent 2']))
        child = persister.save(resource: resource_class.new(title: ['Child'], a_member_of: [parent.id, parent2.id]))
        persister.save(resource: resource_class.new(title: ['Another Resource']))

        expect(query_service.find_references_by(resource: child, property: :a_member_of).map(&:id).to_a).to contain_exactly parent.id, parent2.id
      end

      it "returns an empty array if there are none" do
        child = persister.save(resource: resource_class.new(title: ['Child']))
        expect(query_service.find_references_by(resource: child, property: :a_member_of).to_a).to eq []
      end

      it "removes duplicates" do
        parent = persister.save(resource: resource_class.new)
        child = persister.save(resource: resource_class.new(a_member_of: [parent.id, parent.id]))
        persister.save(resource: resource_class.new)

        expect(query_service.find_references_by(resource: child, property: :a_member_of).map(&:id).to_a).to contain_exactly parent.id
      end

      it "returns nothing if reference not found" do
        child = persister.save(resource: resource_class.new(a_member_of: ["123123123"]))
        persister.save(resource: resource_class.new)

        expect(query_service.find_references_by(resource: child, property: :a_member_of).map(&:id).to_a).to eq []
      end
    end

    context "when the property is ordered" do
      xit "returns all references in order including duplicates" do
        parent = persister.save(resource: resource_class.new)
        parent2 = persister.save(resource: resource_class.new)
        child = persister.save(resource: resource_class.new(an_ordered_member_of: [parent.id, parent2.id, parent.id]))
        persister.save(resource: resource_class.new)

        expect(query_service.find_references_by(resource: child, property: :an_ordered_member_of).map(&:id).to_a).to eq [parent.id, parent2.id, parent.id]
      end

      it "returns nothing if reference not found" do
        child = persister.save(resource: resource_class.new(an_ordered_member_of: ["123123123"]))
        persister.save(resource: resource_class.new)

        expect(query_service.find_references_by(resource: child, property: :an_ordered_member_of).map(&:id).to_a).to eq []
      end
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
