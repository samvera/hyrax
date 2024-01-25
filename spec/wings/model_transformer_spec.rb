# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::ModelTransformer, :active_fedora, :clean_repo do
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

  define :have_a_valkyrie_alternate_id_of do |expected_id_str|
    match do |valkyrie_resource|
      valkyrie_resource.alternate_ids.map(&:id).include?(expected_id_str)
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
      resource = adapter.query_service.find_by_alternate_identifier(alternate_identifier: work.id)

      # Why these antics?  Because there are minor differences that become errors in the
      # have_attributes matcher.  Those differences as printed by Rspec's expectation matcher are as
      # follows:
      #
      #   -:date_created => [Thu, 25 Jan 2024 15:44:23 +0000],
      #   +:date_created => [Thu, 25 Jan 2024 15:44:23.381956010 +0000],
      #    :depositor => "user1",
      #    :description => ["a description"],
      #   -:import_url => #<ActiveTriples::Resource:0x5eaec ID:<http://example.com/fake1>>,
      #   -:publisher => [false],
      #   -:related_url => [#<ActiveTriples::Resource:0x5eb00 ID:<http://example.com/fake1>>, #<ActiveTriples::Resource:0x5eb14 ID:<http://example.com/fake2>>],
      #   +:import_url => #<RDF::URI:0x5eab0 URI:http://example.com/fake1>,
      #   +:publisher => [],
      #   +:related_url => [#<RDF::URI:0x5eac4 URI:http://example.com/fake1>, #<RDF::URI:0x5ead8 URI:http://example.com/fake2>],
      #    :source => [1.125, :moomin],
      #    :title => ["fake title"],
      #
      # The date created is for purposes of a date, equal.  The ActiveTriple ID and URI are the
      # same, and as the spec below illustrates, they are equal (according to their equality
      # matchers).
      errors = []
      [:title, :date_created, :depositor, :description, :import_url, :related_url, :source].each do |attr|
        next if work.public_send(attr) == resource.public_send(attr)
        errors << { attr => [work.public_send(attr), resource.public_send(attr)] }
      end
      errors << { publisher: [work.publisher, resource.publisher] } unless work.publisher.select(&:present?) == resource.publisher.select(&:present?)

      expect(errors).to be_empty
    end

    context 'when handling an auto-generated object' do
      let(:pcdm_object) { Wings::ActiveFedoraConverter.convert(resource: resource) }
      let(:resource) { Hyrax::Test::Transformer::Book.new }

      before do
        module Hyrax::Test
          module Transformer
            class Book < Hyrax::Resource
            end
          end
        end
      end

      after { Hyrax::Test.send(:remove_const, :Transformer) }

      it 'reconstitutes as the correct class' do
        expect(factory.build).to be_a Hyrax::Test::Transformer::Book
      end
    end

    # rubocop:disable RSpec/AnyInstance
    context 'without an existing id' do
      let(:id)        { nil }
      let(:minted_id) { 'bobross' }

      before do
        Hyrax.config.enable_noids = true
        allow_any_instance_of(::Noid::Rails.config.minter_class)
          .to receive(:mint)
          .and_return(minted_id)
      end

      after { Hyrax.config.enable_noids = false }

      it { expect(factory.build).to have_a_valkyrie_alternate_id_of minted_id }
    end
    # rubocop:enable RSpec/AnyInstance

    context 'with an embargo' do
      let(:work) { FactoryBot.create(:embargoed_work) }

      it 'has the correct embargo id' do
        expect(subject.build.embargo.id.id).to eq work.embargo.id
      end
    end

    context 'with a lease' do
      let(:work) { FactoryBot.create(:leased_work) }

      it 'has the correct lease id' do
        expect(subject.build.lease.id.id).to eq work.lease.id
      end
    end

    context 'with an unsaved embargo' do
      let(:work) { FactoryBot.build(:embargoed_work) }

      it 'has the correct embargo details' do
        expect(factory.build.embargo).to have_attributes work.embargo.attributes.symbolize_keys
      end
    end

    context 'with newly saved embargo' do
      let(:work) { FactoryBot.build(:embargoed_work) }

      it 'has the correct embargo id' do
        work.embargo.save

        expect(subject.build.embargo.id.id).to eq work.embargo.id
      end
    end

    context 'with an unsaved lease' do
      let(:work) { FactoryBot.build(:leased_work) }

      it 'has the correct lease details' do
        expect(factory.build.lease).to have_attributes work.lease.attributes.symbolize_keys
      end
    end

    context 'with newly saved lease' do
      let(:work) { FactoryBot.build(:leased_work) }

      it 'has the correct lease id' do
        work.lease.save

        expect(subject.build.lease.id.id).to eq work.lease.id
      end
    end

    context 'with files and derivatives in fileset' do
      let(:file_set)            { FileSet.new }
      let(:original_file)       { File.open(File.join(fixture_path, 'world.png')) }
      let(:thumbnail_file)      { File.open(File.join(fixture_path, 'image.jpg')) }
      let(:extracted_text_file) { File.open(File.join(fixture_path, 'updated-file.txt')) }
      let(:original_type)       { :original_file }
      let(:thumbnail_type)      { :thumbnail }
      let(:extracted_text_type) { :extracted_text }

      before do
        Hydra::Works::AddFileToFileSet.call(file_set, original_file, original_type)
        Hydra::Works::AddFileToFileSet.call(file_set, thumbnail_file, thumbnail_type)
        Hydra::Works::AddFileToFileSet.call(file_set, extracted_text_file, extracted_text_type)
      end

      it 'has the correct reflection ids' do
        resource = described_class.new(pcdm_object: file_set).build
        expect(resource.file_ids).to match_valkyrie_ids_with_active_fedora_ids(file_set.files.map(&:id))
        expect(resource.original_file_id).to eq file_set.original_file.id
        expect(resource.thumbnail_id).to eq file_set.thumbnail.id
        expect(resource.extracted_text_id).to eq file_set.extracted_text.id
      end
    end

    context 'with members' do
      let(:work)        { FactoryBot.create(:work, id: 'pw', title: ['Parent Work']) }
      let(:child_work1) { FactoryBot.create(:work, id: 'cw1', title: ['Child Work 1']) }
      let(:child_work2) { FactoryBot.create(:work, id: 'cw2', title: ['Child Work 2']) }

      context 'and members are ordered' do
        before do
          work.ordered_members << child_work1
          work.ordered_members << child_work2
        end

        it 'sets member_ids to the ids of the ordered members' do
          expect(subject.build.member_ids).to match_valkyrie_ids_with_active_fedora_ids(['cw1', 'cw2'])
        end
      end

      context 'and members are unordered' do
        before do
          work.members << child_work1
          work.members << child_work2
        end

        it 'includes ordered_members too' do
          ordered_members = [FactoryBot.create(:work), FactoryBot.create(:work)]
          ordered_members.each { |w| work.ordered_members << w }

          expect(factory.build.member_ids).to include(*['cw1', 'cw2'] + ordered_members.map(&:id))
        end

        it 'sets member_ids to the ids of the unordered members' do
          expect(subject.build.member_ids).to match_valkyrie_ids_with_active_fedora_ids(['cw1', 'cw2'])
        end
      end
    end

    context 'with parent collections' do
      let(:work) { FactoryBot.create(:work_with_representative_file, with_admin_set: true) }
      let(:parent_col1) { FactoryBot.create(:collection_lw, title: ['Parent Collection'], id: 'pcol1') }
      let(:parent_col2) { FactoryBot.create(:collection_lw, title: ['Parent Collection'], id: 'pcol2') }

      before do
        work.member_of_collections = [parent_col1, parent_col2]
      end

      it 'sets member_of_collection_ids to the parent collection ids' do
        expect(subject.build.member_of_collection_ids).to match_valkyrie_ids_with_active_fedora_ids(['pcol1', 'pcol2'])
      end
    end
  end

  context 'with _id attributes' do
    let(:work) { FactoryBot.create(:work_with_representative_file, with_admin_set: true) }
    before do
      work.thumbnail_id = work.representative_id
    end

    it 'repopulates the _id attributes' do
      resource = subject.build
      expect(resource[:representative_id].to_s).to eq(work.representative_id)
      expect(resource[:thumbnail_id].to_s).to eq(work.thumbnail_id)
      expect(resource[:access_control_id].to_s).to eq(work.access_control_id)
      expect(resource[:admin_set_id].to_s).to eq(work.admin_set_id)
    end
  end

  context 'with a generic work that has open visibility' do
    before { work.visibility = "open" }

    it 'sets the visibility' do
      resource = factory.build

      expect(resource.read_groups).to contain_exactly(*work.read_groups)
      expect(resource.read_users).to contain_exactly(*work.read_users)
      expect(resource.edit_groups).to contain_exactly(*work.edit_groups)
      expect(resource.edit_users).to contain_exactly(*work.edit_users)
    end
  end

  context 'with relationship properties' do
    let(:pcdm_object) { book }
    let(:id)          { 'moomin123' }
    let(:book)        { book_class.new(id: id, **attributes) }
    let(:page1)       { page_class.new(id: 'pg1') }
    let(:page2)       { page_class.new(id: 'pg2') }

    let(:book_class) do
      ActiveFedoraMonograph = Class.new(ActiveFedora::Base) do
        has_many :active_fedora_pages
        property :title, predicate: ::RDF::Vocab::DC.title
        property :contributor, predicate: ::RDF::Vocab::DC.contributor
        property :description, predicate: ::RDF::Vocab::DC.description
      end
    end

    let(:page_class) do
      ActiveFedoraPage = Class.new(ActiveFedora::Base) do
        belongs_to :active_fedora_monograph, predicate: ActiveFedora::RDF::Fcrepo::RelsExt.isPartOf
      end
    end

    after do
      Object.send(:remove_const, :ActiveFedoraPage)
      Object.send(:remove_const, :ActiveFedoraMonograph)
    end

    let(:attributes) do
      {
        title: ['fake title', 'fake title 2'],
        contributor: ['user1'],
        description: ['a description'],
        active_fedora_pages: [page1, page2]
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
      end

      it "skips has_many reflections" do
        expect(factory.build).not_to respond_to :active_fedora_page_ids
      end

      it "populates belongs_to reflections" do
        monograph = book_class.create(**attributes)

        expect(described_class.new(pcdm_object: page1).build)
          .to have_attributes active_fedora_monograph_id: monograph.id
        expect(described_class.new(pcdm_object: page2).build)
          .to have_attributes active_fedora_monograph_id: monograph.id
      end
    end
  end

  context 'build for file' do
    let(:file_set) { FactoryBot.create(:file_set, :image) }
    let(:file) { file_set.original_file }
    let(:pcdm_object) { file_set }

    context 'with content' do
      it 'sets file id in file set resource' do
        expect(subject.build.original_file_id).to eq file.id
      end
    end

    context 'with empty content' do
      before do
        file.content = ''
      end

      it 'sets file id in file set resource' do
        expect(factory.build.original_file_id).to eq file.id
      end
    end

    context 'when no file' do
      let(:file_set) { create(:file_set) }

      it 'does not set file id in file set resource' do
        expect(factory.build.original_file_id).to be_nil
      end
    end
  end

  context 'with an admin set' do
    let(:pcdm_object) { AdminSet.create(title: ['my admin set']) }

    before do
      5.times do |i|
        GenericWork.create(title: [i.to_s], admin_set_id: pcdm_object.id)
      end
    end

    it 'does not have member_ids' do
      expect(factory.build).not_to respond_to :member_ids
    end
  end

  context 'build for access control' do
    let(:af_object) { ActiveFedora::Base.create }
    let(:permission) { { name: "admin@example.com", access: :edit.to_s, type: :person } }
    let(:access_control) do
      Hydra::AccessControl.create.tap do |ac|
        ac.owner = af_object
        ac.permissions.create(permission)
      end
    end
    let(:pcdm_object) { access_control }
    subject(:resource) { factory.build }

    it 'sets permissions' do
      expect(resource.permissions.first.access_to).to eq pcdm_object.permissions.first.access_to_id
      expect(resource.permissions.first.mode.to_s).to eq pcdm_object.permissions.first.access
      expect(resource.permissions.first.agent).to eq pcdm_object.permissions.first.agent_name
    end
  end
end
