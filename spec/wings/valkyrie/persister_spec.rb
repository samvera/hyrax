# frozen_string_literal: true
require 'wings_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'

RSpec.describe Wings::Valkyrie::Persister do
  subject(:persister) { described_class.new(adapter: adapter) }
  let(:adapter) { Wings::Valkyrie::MetadataAdapter.new }
  let(:query_service) { adapter.query_service }

  context "When an AF work exists with an embargo" do
    let(:release_date) { Time.zone.today - 1 }
    let(:a_work) { create(:generic_work, user: user) }
    let(:user) { create(:user) }

    before do
      a_work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      a_work.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      a_work.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      a_work.embargo_release_date = release_date.to_s
      a_work.embargo.save(validate: false)
      a_work.save(validate: false)
    end

    it "can save a resource with an embargo" do
      resources = Hyrax.custom_queries.find_many_by_alternate_ids(alternate_ids: [a_work.id], use_valkyrie: true)
      saved = persister.save(resource: resources.first)
      expect(saved).to be_persisted
      expect(saved.id).not_to be_blank
    end
  end

  context "When passing a Valkyrie::Resource converted from an ActiveFedora::Base" do
    before do
      module Hyrax::Test
        module Persister
          class Book < ActiveFedora::Base
            include Hydra::AccessControls::Permissions
            include Hyrax::CoreMetadata
            include Hydra::WithDepositor
            property :title, predicate: ::RDF::Vocab::DC.title, multiple: true
            property :single_value, predicate: ::RDF::Vocab::DC.relation, multiple: false
          end
        end
      end
    end

    after do
      Hyrax::Test.send(:remove_const, :Persister)
    end

    let(:af_resource_class) { Hyrax::Test::Persister::Book }
    let(:resource_class) { Wings::OrmConverter.to_valkyrie_resource_class(klass: af_resource_class) }
    let(:resource) { resource_class.new(title: ['Foo']) }

    # it_behaves_like "a Valkyrie::Persister"

    it { is_expected.to respond_to(:save).with_keywords(:resource) }
    it { is_expected.to respond_to(:save_all).with_keywords(:resources) }
    it { is_expected.to respond_to(:delete).with_keywords(:resource) }
    it { is_expected.to respond_to(:wipe!) }

    it "can save a resource" do
      expect(resource).not_to be_persisted
      saved = persister.save(resource: resource)
      expect(saved).to be_persisted
      expect(saved.id).not_to be_blank
    end

    it "stores created_at/updated_at" do
      book = persister.save(resource: resource)
      book.title = ["test"]
      book = persister.save(resource: book)
      expect(book.created_at).not_to be_blank
      expect(book.updated_at).not_to be_blank
      expect(book.created_at).not_to be_kind_of Array
      expect(book.updated_at).not_to be_kind_of Array
      expect(book.updated_at > book.created_at).to eq true
    end

    it "can override default id generation with a provided id" do
      id = SecureRandom.uuid
      valkyrie_id = Valkyrie::ID.new(id)
      book = persister.save(resource: resource_class.new(id: id, title: ['Foo']))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.id).to eq valkyrie_id
      expect(reloaded.alternate_ids.first).to eq valkyrie_id
      expect(reloaded).to be_persisted
      expect(reloaded.created_at).not_to be_blank
      expect(reloaded.updated_at).not_to be_blank
      expect(reloaded.created_at).not_to be_kind_of Array
      expect(reloaded.updated_at).not_to be_kind_of Array
    end

    it "doesn't override a resource that already has an ID" do
      book = persister.save(resource: resource_class.new(title: ['Foo']))
      id = book.id
      output = persister.save(resource: book)
      expect(output.id).to eq id
    end

    it "can find that resource again" do
      id = persister.save(resource: resource).id
      expect(query_service.find_by(id: id).internal_resource).to eq resource.internal_resource
    end

    it "can save multiple resources at once" do
      resource2 = resource_class.new
      results = persister.save_all(resources: [resource, resource2])

      expect(results.map(&:id).uniq.length).to eq 2
      expect(persister.save_all(resources: [])).to eq []
    end

    it "can delete objects" do
      persisted = persister.save(resource: resource)
      persister.delete(resource: persisted)

      expect { query_service.find_by(id: persisted.id) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it "can delete all objects" do
      resource2 = resource_class.new
      persister.save_all(resources: [resource, resource2])
      persister.wipe!
      expect(query_service.find_all.to_a.length).to eq 0
    end

    it "can persist single values" do
      resource.single_value = "A single value"
      output = persister.save(resource: resource)
      expect(output.single_value).to eq "A single value"
      reloaded = query_service.find_by(id: output.id)
      reloaded.single_value = nil
      persister.save(resource: reloaded)
      reloaded = query_service.find_by(id: reloaded.id)
      expect(reloaded.single_value).to eq nil
    end
  end

  context 'when passing a FileMetadata node' do
    let(:resource) { Hyrax::FileMetadata.new }

    it 'raises an error because AF declines to save files that do not have content' do
      expect { persister.save(resource: resource) }
        .to raise_error described_class::FailedSaveError
    end

    context 'and it corresponds to a ActiveFedora File' do
      let(:resource) { Hyrax::FileMetadata.new(id: file.id) }
      let(:file) do
        Hydra::PCDM::File.new.tap do |f|
          f.content = "moomin\n"
          f.save
        end
      end

      it 'returns itself' do
        expect(persister.save(resource: resource).id).to eq resource.id
      end

      it 'can update metadata' do
        resource.bit_rate = ['1000']

        expect { persister.save(resource: resource) }
          .to change { Hydra::PCDM::File.find(file.id).bit_rate }
          .to contain_exactly '1000'
      end

      it 'does not update existing content' do
        persister.save(resource: resource)
        file.reload
        expect(file.content).to eq("moomin\n")
      end
    end

    context "and it is metadata about a non-AF file" do
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
      let(:io) { Tempfile.new('moomin-deriviative') }
      let(:resource) { Hyrax::FileMetadata.new(file_identifier: file.id) }
      let(:storage_adapter) { Valkyrie::StorageAdapter.find(:derivatives_disk) }

      let(:file) do
        storage_adapter.upload(file: io, original_filename: 'moomin.txt', resource: file_set)
      end

      it "can save a resource" do
        expect(persister.save(resource: resource)).to be_persisted
      end

      it "can save a resource repeatedly" do
        saved = persister.save(resource: resource)
        expect(persister.save(resource: saved)).to be_persisted
      end

      it "recalls the file id" do
        expect(persister.save(resource: resource))
          .to have_attributes(file_identifier: file.id)
      end

      it "uses OriginalFile as type by default" do
        expect(persister.save(resource: resource))
          .to have_attributes(type: contain_exactly(RDF::URI("http://pcdm.org/use#OriginalFile")))
      end

      it "saves file metadata attributes" do
        resource.file_set_id = file_set.id
        resource.label = 'Comet in Moominland'
        resource.mime_type = 'application/moomin'
        resource.width = 7

        expect(persister.save(resource: resource))
          .to have_attributes(file_set_id: file_set.id,
                              label: contain_exactly('Comet in Moominland'),
                              mime_type: 'application/moomin',
                              width: contain_exactly(7))
      end
    end
  end

  context "When passing a Valkyrie::Resource that was never an ActiveFedora::Base" do
    before do
      class CustomResource < Hyrax::Resource
        attribute :title
        attribute :author
        attribute :member_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID)
        attribute :nested_resource
        attribute :depositor, Valkyrie::Types::String.optional
        attribute :ordered_authors, Valkyrie::Types::Array.of(Valkyrie::Types::Anything).meta(ordered: true)
        attribute :ordered_nested, Valkyrie::Types::Array.of(CustomResource).meta(ordered: true)
        attribute :single_value, Valkyrie::Types::String.optional
      end

      class Custom < ActiveFedora::Base
        property :title,    predicate: ::RDF::URI('http://example.com/ns/title')
        property :author,   predicate: ::RDF::URI('http://example.com/ns/author')
        property :member_ids, predicate: ::RDF::URI.new('http://www.example.com/member_ids'), multiple: true
        property :nested_resource, predicate: ::RDF::URI("http://example.com/nested_resource"), class_name: CustomResource
        property :depositor, predicate: ::RDF::URI("http://example.com/ns/depositor")
        property :ordered_authors, predicate: ::RDF::Vocab::DC.creator
        property :ordered_nested, predicate: ::RDF::URI("http://example.com/ordered_nested")
        accepts_nested_attributes_for :nested_resource
        include Hydra::Works::WorkBehavior
      end
    end
    after do
      Object.send(:remove_const, :CustomResource)
      Object.send(:remove_const, :Custom)
    end

    let(:resource_class) { CustomResource }
    let(:resource) { resource_class.new }

    it { is_expected.to respond_to(:save).with_keywords(:resource) }
    it { is_expected.to respond_to(:save_all).with_keywords(:resources) }
    it { is_expected.to respond_to(:delete).with_keywords(:resource) }

    it "can save a resource" do
      expect(resource).not_to be_persisted
      saved = persister.save(resource: resource)
      expect(saved).to be_persisted
      expect(saved.id).not_to be_blank
      expect(saved.alternate_ids.first).to eq saved.id
    end

    it "can save multiple resources at once" do
      resource2 = resource_class.new
      results = persister.save_all(resources: [resource, resource2])

      expect(results.map(&:id).uniq.length).to eq 2
      expect(persister.save_all(resources: [])).to eq []
    end

    it "can save nested resources" do
      pending "nested resource handling doesn't actually work; we are planning to rework it to behave correctly via https://github.com/samvera/hyrax/issues/3662"
      book2 = resource_class.new(title: "Nested")
      book3 = persister.save(resource: resource_class.new(nested_resource: book2))

      reloaded = query_service.find_by(id: book3.id)
      expect(reloaded.nested_resource.first.title).to eq ["Nested"]
    end

    it "can persist single values" do
      resource.single_value = "user@institution.edu"

      output = persister.save(resource: resource)

      expect(output.single_value).to eq "user@institution.edu"
    end

    it "returns nil for an unset single value" do
      output = persister.save(resource: resource_class.new)

      expect(output.single_value).to be_nil
    end

    it "stores created_at/updated_at" do
      book = persister.save(resource: resource_class.new)
      book.title = "test"
      book = persister.save(resource: book)
      expect(book.created_at).not_to be_blank
      expect(book.updated_at).not_to be_blank
      expect(book.created_at).not_to be_kind_of Array
      expect(book.updated_at).not_to be_kind_of Array
      expect(book.updated_at > book.created_at).to eq true
    end

    it "can handle Boolean RDF properties" do
      boolean_rdf = RDF::Literal.new(false)
      book = persister.save(resource: resource_class.new(title: [boolean_rdf]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly boolean_rdf
    end

    it "can handle custom-typed RDF properties" do
      custom_rdf = RDF::Literal.new("Test", datatype: RDF::URI.parse("http://my_made_up_type"))
      book = persister.save(resource: resource_class.new(title: [custom_rdf]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly custom_rdf
    end

    it "can handle Date RDF properties" do
      pending 'ActiveFedora casts literals to Literal#object, where possible. '\
              'Without an RDFLiteral in Valkyrie::Types to specify casting back, we ' \
              "can't know what the model wants." # pending so if this passes, we fail CI

      date_rdf = RDF::Literal.new(Date.current)
      book = persister.save(resource: resource_class.new(title: [date_rdf]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly date_rdf
    end

    it "can handle DateTime RDF properties" do
      pending 'ActiveFedora casts literals to Literal#object, where possible. '\
              'Without an RDFLiteral in Valkyrie::Types to specify casting back, we ' \
              "can't know what the model wants." # pending so if this passes, we fail CI

      datetime_rdf = RDF::Literal.new(DateTime.current)
      book = persister.save(resource: resource_class.new(title: [datetime_rdf]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly datetime_rdf
    end

    it "can handle Decimal RDF properties" do
      pending 'ActiveFedora casts literals to Literal#object, where possible. '\
              'Without an RDFLiteral in Valkyrie::Types to specify casting back, we ' \
              "can't know what the model wants." # pending so if this passes, we fail CI

      decimal_rdf = RDF::Literal.new(BigDecimal(5.5, 10))
      book = persister.save(resource: resource_class.new(title: [decimal_rdf]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly decimal_rdf
    end

    it "can handle Double RDF properties" do
      pending 'ActiveFedora casts literals to Literal#object, where possible. '\
              'Without an RDFLiteral in Valkyrie::Types to specify casting back, we ' \
              "can't know what the model wants." # pending so if this passes, we fail CI

      double_rdf = RDF::Literal.new(5.5)
      book = persister.save(resource: resource_class.new(title: [double_rdf]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly double_rdf
    end

    it "can handle Integer RDF properties" do
      pending 'ActiveFedora casts literals to Literal#object, where possible. '\
              'Without an RDFLiteral in Valkyrie::Types to specify casting back, we ' \
              "can't know what the model wants." # pending so if this passes, we fail CI

      int_rdf = RDF::Literal.new(17)
      book = persister.save(resource: resource_class.new(title: [int_rdf]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly int_rdf
    end

    it "can handle language-typed RDF properties" do
      language_rdf = RDF::Literal.new("Test", language: :fr)
      book = persister.save(resource: resource_class.new(title: ["Test1", language_rdf]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly "Test1", language_rdf
    end

    it "can handle Time RDF properties" do
      pending 'ActiveFedora casts literals to Literal#object, where possible. '\
              'Without an RDFLiteral in Valkyrie::Types to specify casting back, we ' \
              "can't know what the model wants." # pending so if this passes, we fail CI

      time_rdf = RDF::Literal.new(Time.current)
      book = persister.save(resource: resource_class.new(title: [time_rdf]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly time_rdf
    end

    #  https://github.com/samvera-labs/valkyrie/wiki/Supported-Data-Types
    it "can store booleans" do
      boolean = [false, true]
      book = persister.save(resource: resource_class.new(title: boolean))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly(*boolean)
    end

    it "can store DateTimes" do
      time1 = DateTime.current
      time2 = Time.current.in_time_zone
      book = persister.save(resource: resource_class.new(title: [time1, time2]))

      reloaded = query_service.find_by(id: book.id)

      expect(reloaded.title).to contain_exactly(time1, time2)
    end

    it "can store Floats" do
      decimal = 5.5
      book = persister.save(resource: resource_class.new(title: [decimal]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly decimal
    end

    it "can store integers" do
      book = persister.save(resource: resource_class.new(title: [1]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly 1
    end

    it "can store ::RDF::URIs" do
      book = persister.save(resource: resource_class.new(title: [::RDF::URI("http://example.com")]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly RDF::URI("http://example.com")
    end

    it "can store Valkyrie::IDs" do
      shared_title = persister.save(resource: resource_class.new)
      book = persister.save(resource: resource_class.new(title: [shared_title.id, Valkyrie::ID.new("adapter://1"), "test"]))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.title).to contain_exactly(shared_title.id, Valkyrie::ID.new("adapter://1"), "test")
      expect([shared_title.id, Valkyrie::ID.new("adapter://1"), "test"]).to contain_exactly(*reloaded.title)
    end

    it "can override default id generation with a provided id" do
      id = SecureRandom.uuid
      book = persister.save(resource: resource_class.new(id: id))
      reloaded = query_service.find_by(id: book.id)
      expect(reloaded.id).to eq Valkyrie::ID.new(id)
      expect(reloaded).to be_persisted
      expect(reloaded.created_at).not_to be_blank
      expect(reloaded.updated_at).not_to be_blank
      expect(reloaded.created_at).not_to be_kind_of Array
      expect(reloaded.updated_at).not_to be_kind_of Array
    end

    context "parent tests" do
      let(:book) { persister.save(resource: resource_class.new(title: ['Book'])) }
      let(:book2) { persister.save(resource: resource_class.new(title: ['Book 2'])) }

      it "can order members" do
        book3 = persister.save(resource: resource_class.new(title: ['Book 3']))
        parent = persister.save(resource: resource_class.new(title: ['Parent'], member_ids: [book2.id, book.id]))
        parent.member_ids = parent.member_ids + [book3.id]
        parent = persister.save(resource: parent)
        reloaded = query_service.find_by(id: parent.id)
        expect(reloaded.member_ids).to eq [book2.id, book.id, book3.id]
      end

      it "can remove members" do
        parent = persister.save(resource: resource_class.new(title: ['Parent'], member_ids: [book2.id, book.id]))
        parent.member_ids = parent.member_ids - [book2.id]
        parent = persister.save(resource: parent)
        expect(parent.member_ids).to eq [book.id]
      end
    end

    it "doesn't override a resource that already has an ID" do
      book = persister.save(resource: resource_class.new)
      id = book.id
      output = persister.save(resource: book)
      expect(output.id).to eq id
    end

    # not sure how to fix this one. When a resource wasn't ever in AF, it is persisted as
    # internal_resource="Wings::ActiveFedoraConverter::DefaultWork"
    # so the CustomResource defined above will not be persisted as such.
    it "can find that resource again" do
      id = persister.save(resource: resource).id
      item = query_service.find_by(id: id)
      expect(item).to be_kind_of resource_class
    end

    it "can delete objects" do
      persisted = persister.save(resource: resource)
      persister.delete(resource: persisted)

      expect { query_service.find_by(id: persisted.id) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it "can delete all objects" do
      resource2 = resource_class.new
      persister.save_all(resources: [resource, resource2])
      persister.wipe!
      expect(query_service.find_all.to_a.length).to eq 0
    end

    context "optimistic locking" do
      before do
        class MyLockingResource < Hyrax::Resource
          enable_optimistic_locking
          attribute :title
        end
      end

      after do
        ActiveSupport::Dependencies.remove_constant("MyLockingResource")
      end

      describe "#save" do
        context "when creating a resource" do
          it "returns the value of the system-generated optimistic locking attribute on the resource" do
            resource = MyLockingResource.new(title: ["My Locked Resource"])
            saved_resource = persister.save(resource: resource)

            expect(saved_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK])
              .to include(an_instance_of(Valkyrie::Persistence::OptimisticLockToken))
          end
        end

        context "when updating a resource with a correct lock token" do
          it "successfully saves the resource and returns the updated value of the optimistic locking attribute" do
            resource = MyLockingResource.new(title: ["My Locked Resource"])
            initial_resource = persister.save(resource: resource)
            updated_resource = persister.save(resource: initial_resource)
            expect(initial_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK])
              .not_to eq updated_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
          end
        end

        context "when updating a resource with an incorrect lock token" do
          it "raises a Valkyrie::Persistence::StaleObjectError" do
            resource = MyLockingResource.new(title: ["My Locked Resource"])
            resource = persister.save(resource: resource)
            # update the resource in the datastore to make its token stale
            persister.save(resource: resource)

            expect { persister.save(resource: resource) }.to raise_error(Valkyrie::Persistence::StaleObjectError, /#{resource.id}/)
          end
        end

        context "when lock token is nil" do
          it "successfully saves the resource and returns the updated value of the optimistic locking attribute" do
            resource = MyLockingResource.new(title: ["My Locked Resource"])
            initial_resource = persister.save(resource: resource)
            initial_token = initial_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK].first
            initial_resource.send("#{Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK}=", [])
            updated_resource = persister.save(resource: initial_resource)
            expect(initial_token.serialize)
              .not_to eq(updated_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK].first.serialize)
            expect(updated_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]).not_to be_empty
          end
        end

        context "when there is a token, but it's for a different adapter (migration use case)" do
          it "successfully saves the resource and returns a token for the adapter that was saved to" do
            resource = MyLockingResource.new(title: ["My Locked Resource"])
            initial_resource = persister.save(resource: resource)
            new_token = Valkyrie::Persistence::OptimisticLockToken.new(
              adapter_id: Valkyrie::ID.new("fake_adapter"),
              token: "token"
            )
            initial_resource.send("#{Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK}=", [new_token])
            updated_resource = persister.save(resource: initial_resource)
            expect(new_token.serialize)
              .not_to eq(updated_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK].first.serialize)
            expect(updated_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]).not_to be_empty
          end
        end
      end

      describe "#save_all" do
        context "when creating multiple resources" do
          it "returns an array of resources with their system-generated optimistic locking attributes" do
            resource1 = MyLockingResource.new(title: ["My Locked Resource 1"])
            resource2 = MyLockingResource.new(title: ["My Locked Resource 2"])
            resource3 = MyLockingResource.new(title: ["My Locked Resource 3"])
            saved_resources = persister.save_all(resources: [resource1, resource2, resource3])
            saved_resources.each do |saved_resource|
              expect(saved_resource[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]).not_to be_empty
            end
          end
        end

        context "when updating multiple resources that all have a correct lock token" do
          it "saves the resources and returns them with updated values of the optimistic locking attribute" do
            resource1 = MyLockingResource.new(title: ["My Locked Resource 1"])
            resource2 = MyLockingResource.new(title: ["My Locked Resource 2"])
            resource3 = MyLockingResource.new(title: ["My Locked Resource 3"])
            saved_resources = persister.save_all(resources: [resource1, resource2, resource3])
            initial_lock_tokens = saved_resources.map do |r|
              r[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
            end
            updated_resources = persister.save_all(resources: saved_resources)
            updated_lock_tokens = updated_resources.map do |r|
              r[Valkyrie::Persistence::Attributes::OPTIMISTIC_LOCK]
            end
            expect(initial_lock_tokens & updated_lock_tokens).to be_empty
          end
        end

        context "when one of the resources has an incorrect lock token" do
          it "raises a Valkyrie::Persistence::StaleObjectError" do
            resource1 = MyLockingResource.new(title: ["My Locked Resource 1"])
            resource2 = MyLockingResource.new(title: ["My Locked Resource 2"])
            resource3 = MyLockingResource.new(title: ["My Locked Resource 3"])
            resource1, resource2, resource3 = persister.save_all(resources: [resource1, resource2, resource3])
            # update a resource in the datastore to make its token stale
            persister.save(resource: resource2)

            expect { persister.save_all(resources: [resource1, resource2, resource3]) }
              .to raise_error(Valkyrie::Persistence::StaleObjectError)
          end
        end
      end
    end

    context 'ordered properties' do
      xit "orders string values and returns them in the appropriate order" do
        validate_order ["a", "b", "a"]
      end

      xit "orders boolean values and returns them in the appropriate order" do
        validate_order [true, false, true]
      end

      xit "orders integer values and returns them in the appropriate order" do
        validate_order [1, 2, 1]
      end

      xit "orders date values and returns them in the appropriate order" do
        now = Time.now.round(0).utc
        validate_order [now, now - 3.hours, now - 1.hour]
      end

      xit "orders URIs and returns them in the appropriate order" do
        uri1 = RDF::URI("http://example.com/foo")
        uri2 = RDF::URI("http://example.com/bar")
        uri3 = RDF::URI("http://example.com/baz")
        validate_order [uri1, uri2, uri3]
      end

      xit "orders IDs and returns them in the appropriate order" do
        page1 = persister.save(resource: resource_class.new(authors: ["Page 1"]))
        page2 = persister.save(resource: resource_class.new(authors: ["Page 2"]))
        page3 = persister.save(resource: resource_class.new(authors: ["Page 3"]))
        validate_order [page1.id, page2.id, page3.id]
      end

      xit "orders floating point values and returns them in the appropriate order" do
        validate_order [1.123, 2.222, 1.123]
      end

      xit "orders different types of objects together" do
        validate_order [
          RDF::URI("http://example.com/foo", language: :ita),
          RDF::URI("http://example.com/foo", datatype: RDF::URI("http://datatype")),
          1,
          1.01,
          "Test"
        ]
      end

      xit "orders nested objects with strings" do
        nested1 = resource_class.new(id: Valkyrie::ID.new("resource1"))

        resource.ordered_authors = [nested1, "test"]

        output = persister.save(resource: resource)
        expect(output.ordered_authors[0].id).to eq nested1.id
        expect(output.ordered_authors[1]).to eq "test"
      end

      xit "orders nested objects" do
        nested1 = resource_class.new(id: Valkyrie::ID.new("resource1"), authors: ["Resource 1"])
        nested2 = resource_class.new(id: Valkyrie::ID.new("resource2"), authors: ["Resource 2"])
        nested3 = resource_class.new(id: Valkyrie::ID.new("resource3"), authors: ["Resource 3"])
        values = [nested1, nested2, nested3]

        resource.ordered_nested = values

        output = persister.save(resource: resource)
        expect(output.ordered_nested.map(&:id)).to eq values.map(&:id)

        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.ordered_nested.map(&:id)).to eq values.map(&:id)
      end

      def validate_order(values)
        resource.ordered_authors = values
        output = persister.save(resource: resource)
        expect(output.ordered_authors).to eq(values)

        reloaded = query_service.find_by(id: output.id)
        expect(reloaded.ordered_authors).to eq(values)
      end
    end
  end
end
