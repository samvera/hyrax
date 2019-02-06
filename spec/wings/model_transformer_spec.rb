# frozen_string_literal: true
require 'spec_helper'
require 'wings/model_transformer'

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
  end

  context 'for PCDM & Hydra-Works models', :clean_repo do
    let(:collection1) { build(:public_collection_lw, id: 'col1', title: ['Collection 1']) }
    let(:collection2) { build(:public_collection_lw, id: 'col2', title: ['Collection 2']) }
    let(:collection3) { build(:public_collection_lw, id: 'col3', title: ['Collection 3']) }
    let(:work1)       { build(:work, id: 'wk1', title: ['Work 1']) }
    let(:work2)       { build(:work, id: 'wk2', title: ['Work 2']) }
    let(:work3)       { build(:work, id: 'wk3', title: ['Work 3']) }
    let(:fileset1)    { build(:file_set, id: 'fs1', title: ['Fileset 1']) }
    let(:fileset2)    { build(:file_set, id: 'fs2', title: ['Fileset 2']) }

    describe '#build' do
      context 'for parent collection' do
        before do
          collection1.members = [work1, work2, collection2, collection3]
          collection1.save!
        end

        let(:pcdm_object) { collection1 }

        it 'returns a Valkyrie::Resource' do
          expect(subject.build).to be_a Valkyrie::Resource
        end

        it 'has the id of the active_fedora_object' do
          expect(subject.build).to have_a_valkyrie_alternate_id_of collection1.id
        end

        it 'has attributes for the PCDM model' do
          expect(subject.build)
            .to have_attributes title: collection1.title
          expect_ids_to_match(subject.build.member_ids, [work1.id, work2.id, collection2.id, collection3.id])
        end
      end

      context 'for child collection' do
        let(:pcdm_object) { collection3 }

        before do
          collection3.member_of_collections = [collection1, collection2]
          collection3.save!
        end

        it 'returns a Valkyrie::Resource' do
          expect(subject.build).to be_a Valkyrie::Resource
        end

        it 'has the id of the active_fedora_object' do ###
          expect(subject.build).to have_a_valkyrie_alternate_id_of collection3.id
        end

        it 'has attributes matching the active_fedora_object' do
          expect(subject.build)
            .to have_attributes title: collection3.title
          expect_ids_to_match(subject.build.member_of_collection_ids, ['col1', 'col2'])
        end
      end

      context 'for work in collection' do
        let(:pcdm_object) { work1 }

        before do
          work1.member_of_collections = [collection1, collection2]
          work1.save!
        end

        it 'returns a Valkyrie::Resource' do
          expect(subject.build).to be_a Valkyrie::Resource
        end

        it 'has the id of the active_fedora_object' do ###
          expect(subject.build).to have_a_valkyrie_alternate_id_of work1.id
        end

        it 'has attributes matching the active_fedora_object' do
          expect(subject.build)
            .to have_attributes title: work1.title
          expect_ids_to_match(subject.build.member_of_collection_ids, ['col1', 'col2'])
        end
      end

      context 'work with works and filesets' do
        let(:pcdm_object) { work1 }

        before do
          work1.members = [work2, work3, fileset1, fileset2]
          work1.save!
        end

        it 'returns a Valkyrie::Resource' do
          expect(subject.build).to be_a Valkyrie::Resource
        end

        it 'has the id of the active_fedora_object' do ###
          expect(subject.build).to have_a_valkyrie_alternate_id_of work1.id
        end

        it 'has attributes matching the active_fedora_object' do
          expect(subject.build)
            .to have_attributes title: work1.title
          expect_ids_to_match(subject.build.member_ids, [work2.id, work3.id, fileset1.id, fileset2.id])
        end
      end
    end
  end

  def expect_ids_to_match(valkyrie_ids, expected_ids)
    expect(valkyrie_ids.map(&:id)).to match_array expected_ids
  end
end
