# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'

RSpec.describe Wings::Valkyrie::Persister do
  before do
    class Book < ActiveFedora::Base
      property :title, predicate: ::RDF::Vocab::DC.title, multiple: true
    end
  end

  after do
    Object.send(:remove_const, :Book)
  end

  subject(:persister) { described_class.new(adapter: adapter) }
  let(:adapter) { Wings::Valkyrie::MetadataAdapter.new }
  let(:query_service) { adapter.query_service }
  let(:af_resource_class) { Book }
  let(:resource_class) { Wings::ModelTransformer.to_valkyrie_resource_class(klass: af_resource_class) }
  let(:resource) { resource_class.new(title: ['Foo']) }

  # it_behaves_like "a Valkyrie::Persister"

  it { is_expected.to respond_to(:save).with_keywords(:resource) }
  xit { is_expected.to respond_to(:save_all).with_keywords(:resources) }
  xit { is_expected.to respond_to(:delete).with_keywords(:resource) }

  it "can save a resource" do
    expect(resource).not_to be_persisted
    saved = persister.save(resource: resource)
    # expect(saved).to be_persisted
    expect(saved.id).not_to be_blank
  end

  xit "stores created_at/updated_at" do
    book = persister.save(resource: resource)
    book.title = ["test"]
    book = persister.save(resource: book)
    expect(book.created_at).not_to be_blank
    expect(book.updated_at).not_to be_blank
    expect(book.created_at).not_to be_kind_of Array
    expect(book.updated_at).not_to be_kind_of Array
    expect(book.updated_at > book.created_at).to eq true
  end

  xit "can override default id generation with a provided id" do
    id = SecureRandom.uuid
    book = persister.save(resource: resource_class.new(id: id, title: ['Foo']))
    reloaded = query_service.find_by(id: book.id)
    expect(reloaded.id).to eq Valkyrie::ID.new(id)
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
end
