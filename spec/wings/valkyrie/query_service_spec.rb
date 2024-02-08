# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'

RSpec.describe Wings::Valkyrie::QueryService, :active_fedora, :clean_repo do
  before do
    module Hyrax::Test
      module QueryService
        class Book < ActiveFedora::Base
          include Hyrax::WorkBehavior
          include Hydra::AccessControls::Permissions
          property :title, predicate: ::RDF::Vocab::DC.title, multiple: true
          property :a_member_of, predicate: ::RDF::URI.new('http://www.example.com/a_member_of'), multiple: true do |index|
            index.as :symbol
          end
          property :an_ordered_member_of, predicate: ::RDF::URI.new('http://www.example.com/an_ordered_member_of'), multiple: true
        end

        class Image < ActiveFedora::Base
          include Hydra::AccessControls::Permissions
          property :title, predicate: ::RDF::Vocab::DC.title, multiple: true
        end
      end
    end
  end

  after do
    Hyrax::Test.send(:remove_const, :QueryService)
  end

  subject(:query_service) { described_class.new(adapter: adapter) }
  let(:adapter) { Wings::Valkyrie::MetadataAdapter.new }
  let(:persister) { Wings::Valkyrie::Persister.new(adapter: adapter) }
  let(:af_resource_class) { Hyrax::Test::QueryService::Book }
  let(:af_image_resource_class) { Hyrax::Test::QueryService::Image }
  let(:resource_class) { Wings::OrmConverter.to_valkyrie_resource_class(klass: af_resource_class) }
  let(:image_resource_class) { Wings::OrmConverter.to_valkyrie_resource_class(klass: af_image_resource_class) }
  let(:resource) { resource_class.new(title: ['Foo']) }

  # it_behaves_like "a Valkyrie query provider" # 11 failing tests

  # rubocop:disable RSpec/ExampleLength
  it 'responds to expected methods' do
    expect(subject).to respond_to(:find_by).with_keywords(:id)
    expect(subject).to respond_to(:resource_factory)
    expect(subject).to respond_to(:find_all).with(0).arguments
    expect(subject).to respond_to(:find_all_of_model).with_keywords(:model)
    expect(subject).to respond_to(:find_many_by_ids).with_keywords(:ids)
    expect(subject).to respond_to(:find_by_alternate_identifier).with_keywords(:alternate_identifier)
    expect(subject).to respond_to(:find_members).with_keywords(:resource)
    expect(subject).to respond_to(:find_references_by).with_keywords(:resource, :property)
    expect(subject).to respond_to(:find_inverse_references_by).with_keywords(:resource, :property)
    expect(subject).to respond_to(:find_inverse_references_by).with_keywords(:id, :property)
    expect(subject).to respond_to(:find_parents).with_keywords(:resource)
  end
  # rubocop:enable RSpec/ExampleLength

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
      expect { query_service.find_by(id: ::Valkyrie::ID.new("123123123")) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'raises an error if the id is not a Valkyrie::ID or a string' do
      expect { query_service.find_by(id: 123) }.to raise_error ArgumentError
    end
  end

  describe ".count_all_of_model" do
    it "counts all of that model" do
      persister.save(resource: resource_class.new)
      persister.save(resource: Monograph.new)
      persister.save(resource: Monograph.new)
      expect(query_service.count_all_of_model(model: Monograph)).to eq(2)
    end

    it "can count AdminSet" do
      expect(query_service.count_all_of_model(model: AdminSet)).to eq(0)
    end

    it "can count Hyrax::AdministrativeSet" do
      expect(query_service.count_all_of_model(model: Hyrax::AdministrativeSet)).to eq(0)
    end

    it "can count the configured Hyrax.config.admin_set_model" do
      expect(query_service.count_all_of_model(model: Hyrax.config.admin_set_class)).to eq(0)
    end

    it "can count Collection" do
      expect(query_service.count_all_of_model(model: Collection)).to eq(0)
    end

    it "can count Hyrax::PcdmCollection" do
      expect(query_service.count_all_of_model(model: Hyrax::PcdmCollection)).to eq(0)
    end

    it "can count the configured Hyrax.config.admin_set_model" do
      expect(query_service.count_all_of_model(model: Hyrax.config.collection_class)).to eq(0)
    end
  end

  describe ".find_all", clean_repo: true do
    before do
      allow(Hyrax.config).to receive(:curation_concerns).and_return(Hyrax.config.curation_concerns.append(::Collection).append(af_resource_class))
    end

    it "returns all created resources" do
      work = create(:generic_work)
      resource1 = persister.save(resource: resource_class.new)
      resource2 = persister.save(resource: resource_class.new)

      expect(query_service.find_all.map(&:id))
        .to include(resource1.id, resource2.id, Valkyrie::ID.new(work.id))
    end

    it "returns an empty array if there are none" do
      expect(query_service.find_all.to_a).to eq []
    end

    context 'with valkyrie native model' do
      let!(:resources) do
        [FactoryBot.valkyrie_create(:hyrax_work),
         FactoryBot.valkyrie_create(:hyrax_work),
         FactoryBot.valkyrie_create(:hyrax_work)]
      end

      it 'finds the resources' do
        expect(query_service.find_all.map(&:id))
          .to include(*resources.map(&:id))
      end
    end
  end

  describe ".find_all_of_model", clean_repo: true do
    it "returns all of that model" do
      persister.save(resource: resource_class.new)
      resource2 = persister.save(resource: image_resource_class.new)

      expect(query_service.find_all_of_model(model: image_resource_class))
        .to contain_exactly(have_attributes(id: resource2.id))
    end

    it "returns an empty array if there are none" do
      persister.save(resource: resource_class.new)
      persister.save(resource: resource_class.new)

      expect(query_service.find_all_of_model(model: image_resource_class).to_a).to eq []
    end

    context 'with a native resource class' do
      it 'returns all of the model' do
        persister.save(resource: resource_class.new)
        saved = persister.save(resource: Hyrax::Test::SimpleWork.new)

        expect(query_service.find_all_of_model(model: Hyrax::Test::SimpleWork).map(&:id))
          .to contain_exactly saved.id
      end
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

      expect { query_service.find_by_alternate_identifier(alternate_identifier: Valkyrie::ID.new("123123123")) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it "raises a Valkyrie::Persistence::ObjectNotFoundError for a non-found alternate identifier" do
      expect { query_service.find_by_alternate_identifier(alternate_identifier: Valkyrie::ID.new("123123123")) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'raises an error if the alternate identifier is not a Valkyrie::ID or a string' do
      expect { query_service.find_by_alternate_identifier(alternate_identifier: 123) }
        .to raise_error ArgumentError
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

    context 'when use_valkyrie: false' do
      it 'returns an ActiveFedora object' do
        resource = resource_class.new
        resource.alternate_ids = [Valkyrie::ID.new('p9s0xfj')]
        resource = persister.save(resource: resource)
        id = resource.alternate_ids.first

        found = query_service.find_by_alternate_identifier(alternate_identifier: id, use_valkyrie: false)
        expect(found.id).to eq resource.id.id
        expect(found).to be_persisted
        expect(found).to be_a(ActiveFedora::Base)
      end

      it 'returns an ActiveFedora error' do
        expect { query_service.find_by_alternate_identifier(alternate_identifier: Valkyrie::ID.new("123123123"), use_valkyrie: false) }
          .to raise_error ActiveFedora::ObjectNotFoundError
      end
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

  describe ".find_members" do
    context "without filtering by model" do
      let(:af_resource_class) { GenericWork }
      subject { query_service.find_members(resource: parent) }

      context "when the object has members" do
        let!(:child1) { persister.save(resource: resource_class.new(title: ['Child 1'])) }
        let!(:child2) { persister.save(resource: resource_class.new(title: ['Child 2'])) }
        let(:parent) { persister.save(resource: resource_class.new(title: ['Parent'], member_ids: [child2.id, child1.id])) }

        it "returns all a resource's members in order" do
          expect(subject.map(&:id).to_a).to eq [child2.id, child1.id]
        end

        context "when something is member more than once" do
          let(:parent) { persister.save(resource: resource_class.new(title: ['Parent'], member_ids: [child1.id, child2.id, child1.id])) }
          xit "includes duplicates" do
            expect(subject.map(&:id).to_a).to eq [child1.id, child2.id, child1.id]
          end
        end
      end

      context "when there's no resource ID" do
        let(:parent) { resource_class.new(title: ['Parent']) }

        it "doesn't error" do
          expect(subject).not_to eq nil
          expect(subject.to_a).to eq []
        end
      end

      context "when there are no members" do
        let(:parent) { persister.save(resource: resource_class.new(title: ['Parent'])) }

        it "returns an empty array" do
          expect(subject.to_a).to eq []
        end
      end

      context "when the model doesn't have member_ids" do
        let(:parent) { persister.save(resource: image_resource_class.new) }

        it "returns an empty array" do
          expect(subject.to_a).to eq []
        end
      end
    end

    context "filtering by model" do
      subject { query_service.find_members(resource: parent, model: resource_class) }
      let(:gw_resource_class) { GenericWork }
      let(:parent_resource_class) { Wings::OrmConverter.to_valkyrie_resource_class(klass: gw_resource_class) }

      context "when the object has members" do
        let(:child1) { persister.save(resource: resource_class.new(title: ['Child 1'])) }
        let(:child2) { persister.save(resource: parent_resource_class.new(title: ['Child 2'])) }
        let(:child3) { persister.save(resource: resource_class.new(title: ['Child 3'])) }
        let(:parent) { persister.save(resource: parent_resource_class.new(title: ['Parent'], member_ids: [child3.id, child2.id, child1.id])) }

        it "returns all a resource's members in order" do
          expect(subject.map(&:id).to_a).to eq [child3.id, child1.id]
        end
      end

      context "when there are no members that match the filter" do
        let(:child2) { persister.save(resource: parent_resource_class.new(title: ['Child 2'])) }
        let(:parent) { persister.save(resource: parent_resource_class.new(title: ['Parent'], member_ids: [child2.id])) }

        it "returns an empty array" do
          expect(subject.to_a).to eq []
        end
      end
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

  describe ".find_inverse_references_by" do
    context "when the resource is saved" do
      context "when the property is unordered" do
        it "returns everything which references the given resource by the given property" do
          parent = persister.save(resource: resource_class.new(title: ['parent']))
          parent2 = persister.save(resource: resource_class.new(title: ['parent2']))
          child = persister.save(resource: resource_class.new(title: ['child'], a_member_of: [parent.id]))
          child2 = persister.save(resource: resource_class.new(title: ['child2'], a_member_of: [parent.id, parent2.id, parent.id]))
          persister.save(resource: resource_class.new(title: ['resource']))
          persister.save(resource: image_resource_class.new(title: ['resource 2']))

          expect(query_service.find_inverse_references_by(resource: parent, property: :a_member_of).map(&:id).to_a).to contain_exactly child.id, child2.id
        end

        it "returns an empty array if there are none" do
          parent = persister.save(resource: resource_class.new(title: ['parent']))

          expect(query_service.find_inverse_references_by(resource: parent, property: :a_member_of).to_a).to eq []
        end
      end

      # not yet supported by the wings persister
      context "when the property is ordered" do
        xit "returns everything which references the given resource by the given property" do
          parent = persister.save(resource: resource_class.new)
          child = persister.save(resource: resource_class.new(an_ordered_member_of: [parent.id]))
          child2 = persister.save(resource: resource_class.new(an_ordered_member_of: [parent.id, parent.id]))
          persister.save(resource: resource_class.new)
          persister.save(resource: Valkyrie::Specs::SecondResource.new)

          expect(query_service.find_inverse_references_by(resource: parent, property: :an_ordered_member_of).map(&:id).to_a).to contain_exactly child.id, child2.id
        end
      end
    end

    context "when id is passed instead of resource" do
      it "returns everything which references the given resource by the given property" do
        parent = persister.save(resource: resource_class.new(title: ['parent']))
        parent2 = persister.save(resource: resource_class.new(title: ['parent2']))
        child = persister.save(resource: resource_class.new(title: ['child'], a_member_of: [parent.id]))
        child2 = persister.save(resource: resource_class.new(title: ['child2'], a_member_of: [parent.id, parent2.id, parent.id]))
        persister.save(resource: resource_class.new(title: ['resource']))
        persister.save(resource: image_resource_class.new(title: ['resource 2']))

        expect(query_service.find_inverse_references_by(id: parent.alternate_ids.first, property: :a_member_of).map(&:id).to_a).to contain_exactly child.id, child2.id
      end
    end

    context "when neither id nor resource is passed" do
      it "raises an error" do
        expect { query_service.find_inverse_references_by(property: :a_member_of) }.to raise_error ArgumentError
      end
    end

    context "when the resource is not saved" do
      it "raises an error" do
        parent = resource_class.new(title: ['parent'])

        expect { query_service.find_inverse_references_by(resource: parent, property: :a_member_of).to_a }.to raise_error(ArgumentError, "Resource has no id; is it persisted?")
      end
    end
  end

  describe ".find_parents" do
    it "returns all parent resources" do
      child1 = persister.save(resource: resource_class.new(title: ['child 1']))
      child2 = persister.save(resource: resource_class.new(title: ['child 2']))
      parent = persister.save(resource: resource_class.new(title: ['parent'], member_ids: [child1.id, child2.id]))
      parent2 = persister.save(resource: resource_class.new(title: ['parent 2'], member_ids: [child1.id]))

      expect(query_service.find_parents(resource: child1).map(&:id).to_a).to contain_exactly parent.id, parent2.id
    end

    it "returns an empty array if there are none" do
      child1 = persister.save(resource: resource_class.new(title: ['child 1']))

      expect(query_service.find_parents(resource: child1).to_a).to eq []
    end

    it "doesn't return same parent twice" do
      child1 = persister.save(resource: resource_class.new(title: ['child 1']))
      parent = persister.save(resource: resource_class.new(title: ['parent'], member_ids: [child1.id, child1.id]))
      parent2 = persister.save(resource: resource_class.new(title: ['parent 2'], member_ids: [child1.id]))

      expect(query_service.find_parents(resource: child1).map(&:id).to_a).to contain_exactly parent.id, parent2.id
    end

    context "when the model doesn't have member_ids" do
      let(:child1) { persister.save(resource: image_resource_class.new) }

      it "returns an empty array if there are none" do
        expect(query_service.find_parents(resource: child1).to_a).to eq []
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
