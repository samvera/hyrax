# frozen_string_literal: true
require 'spec_helper'
require 'wings/model_transformer'
require 'wings/valkyrie_monkey_patch'

RSpec.describe Wings::ModelTransformer do
  subject(:factory) { described_class.new(pcdm_object: pcdm_object) }
  let(:pcdm_object) { work }
  let(:adapter)     { Valkyrie::MetadataAdapter.find(:memory) }
  let(:id)          { 'moomin123' }
  let(:persister)   { adapter.persister }
  let(:work)        { GenericWork.new(id: id, **attributes) }

  let(:uris) do
    [RDF::URI('http://example.com/fake1'),
     RDF::URI('http://example.com/fake2')]
  end

  let(:attributes) do
    {
      title: ['fake title'],
      date_created: [Time.now.utc],
      depositor: 'user1',
      description: ['a description'],
      import_url: uris.first,
      publisher: [false],
      related_url: uris,
      source: [1.125, :moomin]
    }
  end

  before(:context) do
    Valkyrie::MetadataAdapter.register(
      Valkyrie::Persistence::Memory::MetadataAdapter.new,
      :memory
    )

    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Memory.new,
      :memory
    )
  end

  # TODO: extract to Valkyrie?
  define :have_a_valkyrie_alternate_id_of do |expected_id_str|
    match do |valkyrie_resource|
      valkyrie_resource.alternate_ids.map(&:id).include?(expected_id_str)
    end
  end

  describe '.convert_class_name_to_valkyrie_resource_class' do
    context 'when given a ActiveFedora class name (eg. a constant that responds to #properties)' do
      it 'creates a Valkyrie::Resource class' do
        subject = described_class.convert_class_name_to_valkyrie_resource_class('GenericWork')
        expect(subject.new).to be_a Valkyrie::Resource
      end
    end
  end

  describe '.to_valkyrie_resource_class' do
    context 'when given a ActiveFedora class (eg. a constant that responds to #properties)' do
      context 'for the returned object (e.g. a class)' do
        subject { described_class.to_valkyrie_resource_class(klass: GenericWork) }
        it 'will be Valkyrie::Resource build' do
          expect(subject.new).to be_a Valkyrie::Resource
        end
        it 'has a to_s instance that delegates to the given klass' do
          expect(subject.to_s).to eq(GenericWork.to_s)
        end
        it 'has a internal_resource instance that is the given klass' do
          expect(subject.internal_resource).to eq(GenericWork)
        end
      end
    end
    context 'when given a non-ActiveFedora class' do
      it 'raises an exception' do
        expect { described_class.to_valkyrie_resource_class(klass: String) }.to raise_error
      end
    end
  end

  describe '.for' do
    it 'returns a Valkyrie::Resource' do
      expect(described_class.for(work)).to be_a Valkyrie::Resource
    end
  end

  describe '#build' do
    it 'returns a Valkyrie::Resource' do
      expect(factory.build).to be_a Valkyrie::Resource
    end

    it 'has the id of the pcdm_object' do
      expect(factory.build).to have_a_valkyrie_alternate_id_of work.id
    end

    it 'has attributes matching the pcdm_object' do
      expect(factory.build)
        .to have_attributes title: work.title,
                            date_created: work.date_created,
                            depositor: work.depositor,
                            description: work.description
    end

    it 'round trips attributes' do # rubocop:disable RSpec/ExampleLength
      persister.save(resource: factory.build)

      expect(adapter.query_service.find_by_alternate_identifier(alternate_identifier: work.id))
        .to have_attributes title: work.title,
                            date_created: work.date_created,
                            depositor: work.depositor,
                            description: work.description,
                            import_url: work.import_url,
                            publisher: work.publisher,
                            related_url: work.related_url,
                            source: work.source
    end
  end

  context 'with relationship properties' do
    let(:pcdm_object) { book }
    let(:id)          { 'moomin123' }
    let(:book)        { book_class.new(id: id, **attributes) }
    let(:page1)       { page_class.new(id: 'pg1') }
    let(:page2)       { page_class.new(id: 'pg2') }

    let(:book_class) do
      Book = Class.new(ActiveFedora::Base) do
        has_many :pages
        property :title, predicate: ::RDF::Vocab::DC.title
        property :contributor, predicate: ::RDF::Vocab::DC.contributor
        property :description, predicate: ::RDF::Vocab::DC.description
      end
    end

    let(:page_class) do
      Page = Class.new(ActiveFedora::Base) do
        belongs_to :book_with_pages, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
      end
    end

    after do
      Object.send(:remove_const, :Page)
      Object.send(:remove_const, :Book)
    end

    let(:attributes) do
      {
        title: ['fake title', 'fake title 2'],
        contributor: ['user1'],
        description: ['a description'],
        pages: [page1, page2]
      }
    end

    describe '.for' do
      it 'returns a Valkyrie::Resource' do
        expect(described_class.for(book)).to be_a Valkyrie::Resource
      end
    end

    describe '#build' do
      it 'returns a Valkyrie::Resource' do
        expect(subject.build).to be_a Valkyrie::Resource
      end

      it 'has the id of the active_fedora_object' do
        expect(subject.build).to have_a_valkyrie_alternate_id_of book.id
      end

      it 'has attributes matching the active_fedora_object' do
        expect(subject.build)
          .to have_attributes title: book.title,
                              contributor: book.contributor,
                              description: book.description
        expect_ids_to_match(subject.build.page_ids, ['pg1', 'pg2'])
      end
    end

    def expect_ids_to_match(valkyrie_ids, expected_ids)
      expect(valkyrie_ids.map(&:id)).to match_array expected_ids
    end
  end
end
