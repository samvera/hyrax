require 'valkyrie/specs/shared_specs'
require 'hyrax/specs/shared_specs/metadata'

RSpec.shared_examples 'a Hyrax::Resource' do
  subject(:resource) { described_class.new }
  let(:adapter)      { Valkyrie::MetadataAdapter.find(:test_adapter) }

  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  describe '#alternate_ids' do
    let(:id) { Valkyrie::ID.new('fake_identifier') }

    it 'has an attribute for alternate ids' do
      expect { resource.alternate_ids = id }
        .to change { resource.alternate_ids }
        .to contain_exactly id
    end
  end

  describe '#class' do
    subject(:klass) { resource.class }

    it { is_expected.to respond_to :collection? }
    it { is_expected.to respond_to :file? }
    it { is_expected.to respond_to :file_set? }
    it { is_expected.to respond_to :pcdm_collection? }
    it { is_expected.to respond_to :pcdm_object? }
    it { is_expected.to respond_to :work? }
  end

  it do
    is_expected.to respond_to :collection?
    expect(resource.collection?).to eq resource.class.collection?
  end
  it do
    is_expected.to respond_to :file?
    expect(resource.file?).to eq resource.class.file?
  end
  it do
    is_expected.to respond_to :file_set?
    expect(resource.file_set?).to eq resource.class.file_set?
  end
  it do
    is_expected.to respond_to :pcdm_collection?
    expect(resource.pcdm_collection?).to eq resource.class.pcdm_collection?
  end
  it do
    is_expected.to respond_to :pcdm_object?
    expect(resource.pcdm_object?).to eq resource.class.pcdm_object?
  end
  it do
    is_expected.to respond_to :work?
    expect(resource.work?).to eq resource.class.work?
  end
end

RSpec.shared_examples 'belongs to collections' do
  subject(:model)        { described_class.new }
  let(:adapter)          { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:persister)        { adapter.persister }
  let(:query_service)    { adapter.query_service }
  let(:collection_class) { Hyrax::PcdmCollection }

  describe 'collection membership' do
    it 'is in no collections by default' do
      expect(model.member_of_collection_ids).to be_empty
    end

    it 'can be added to collections' do
      collection_ids = [Valkyrie::ID.new('coll_1'), Valkyrie::ID.new('coll_2')]

      expect { model.member_of_collection_ids = collection_ids }
        .to change { model.member_of_collection_ids }
        .to contain_exactly(*collection_ids)
    end

    it 'is not in the same collection twice' do
      id = Valkyrie::ID.new('coll_1')
      collection_ids = [id, id]

      expect { model.member_of_collection_ids = collection_ids }
        .to change { model.member_of_collection_ids }
        .to contain_exactly id
    end

    context 'when in collections' do
      let!(:model) do
        m = described_class.new(member_of_collection_ids: collections.map(&:id))
        persister.save(resource: m)
      end

      let(:collections) do
        [collection_class.new, collection_class.new, collection_class.new]
          .map! { |w| persister.save(resource: w) }
      end

      it 'can query membership' do
        expect(
          query_service.find_references_by(resource: model,
                                           property: :member_of_collection_ids)
        ).to contain_exactly(*collections)
      end

      it 'can query members of collection' do
        expect(
          query_service.find_inverse_references_by(resource: collections.first,
                                                   property: :member_of_collection_ids)
        ).to contain_exactly model
      end
    end
  end
end

RSpec.shared_examples 'has members' do
  subject(:model)     { described_class.new }
  let(:adapter)       { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:persister)     { adapter.persister }
  let(:query_service) { adapter.query_service }

  describe 'members' do
    it 'has empty member_ids by default' do
      expect(model.member_ids).to be_empty
    end

    it 'has empty members by default' do
      expect(query_service.find_members(resource: model)).to be_empty
    end

    context 'with members' do
      let(:member_works) do
        [described_class.new, described_class.new, described_class.new]
          .map! { |w| persister.save(resource: w) }
      end

      let(:member_ids) { member_works.map(&:id) }

      before { model.member_ids = member_ids }

      it 'has member_ids' do
        expect(model.member_ids).to eq member_ids
      end

      it 'can query members' do
        expect(query_service.find_members(resource: model)).to eq member_works
      end

      it 'can have the same member multiple times' do
        expect { model.member_ids << member_ids.first }
          .to change { query_service.find_members(resource: model) }
          .to eq(member_works + [member_works.first])
      end
    end
  end
end

RSpec.shared_examples 'a Hyrax::PcdmCollection' do
  subject(:collection) { described_class.new }

  it_behaves_like 'a Hyrax::Resource'
  it_behaves_like 'a model with core metadata'
  it_behaves_like 'has members'

  describe '#class' do
    subject(:klass) { collection.class }

    it { is_expected.to be_collection }
    it { is_expected.not_to be_file }
    it { is_expected.not_to be_file_set }
    it { is_expected.to be_pcdm_collection }
    it { is_expected.not_to be_pcdm_object }
    it { is_expected.not_to be_work }
  end

  describe '#collection_type_gid' do
    let(:gid) { Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id.to_s }

    it 'has a GlobalID for a collection type' do
      expect { collection.collection_type_gid = gid }
        .to change { collection.collection_type_gid }
        .to gid
    end
  end
end

RSpec.shared_examples 'a Hyrax::AdministrativeSet' do
  subject(:admin_set) { described_class.new }

  it_behaves_like 'a Hyrax::Resource'
  it_behaves_like 'a model with core metadata'

  describe '#class' do
    subject(:klass) { admin_set.class }

    it { is_expected.to be_collection }
    it { is_expected.not_to be_file }
    it { is_expected.not_to be_file_set }
    it { is_expected.to be_pcdm_collection }
    it { is_expected.not_to be_pcdm_object }
    it { is_expected.not_to be_work }
  end

  it 'has an #alternative_title' do
    expect { admin_set.alternative_title = ['Moomin'] }
      .to change { admin_set.alternative_title }
      .to contain_exactly('Moomin')
  end

  it 'has an #creator' do
    expect { admin_set.creator = ['user1'] }
      .to change { admin_set.creator }
      .to contain_exactly('user1')
  end

  it 'has an #description' do
    expect { admin_set.description = ['lorem ipsum'] }
      .to change { admin_set.description }
      .to contain_exactly('lorem ipsum')
  end

  describe '#collection_type_gid' do
    let(:gid) { Hyrax::CollectionType.find_or_create_admin_set_type.to_global_id }

    it 'has a GlobalID for a collection type' do
      expect(admin_set.collection_type_gid).to eq gid
    end
  end
end

RSpec.shared_examples 'a Hyrax::Work' do
  subject(:work)      { described_class.new }
  let(:adapter)       { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:persister)     { adapter.persister }
  let(:query_service) { adapter.query_service }

  it_behaves_like 'a Hyrax::Resource'
  it_behaves_like 'a model with core metadata'
  it_behaves_like 'belongs to collections'
  it_behaves_like 'has members'

  describe '#class' do
    subject(:klass) { work.class }

    it { is_expected.not_to be_collection }
    it { is_expected.not_to be_file }
    it { is_expected.not_to be_file_set }
    it { is_expected.not_to be_pcdm_collection }
    it { is_expected.to be_pcdm_object }
    it { is_expected.to be_work }
  end

  describe '#admin_set_id' do
    it 'is nil by default' do
      expect(work.admin_set_id).to be_nil
    end

    it 'has admin_set_id' do
      expect { work.admin_set_id = 'admin_set_1' }
        .to change { work.admin_set_id&.id }
        .to 'admin_set_1'
    end

    context 'with a saved admin set' do
      let(:admin_set) { persister.save(resource: Hyrax::AdministrativeSet.new) }

      before { work.admin_set_id = admin_set.id }

      it 'can query admin set' do
        saved = persister.save(resource: work)

        expect(query_service.find_references_by(resource: saved, property: :admin_set_id))
          .to contain_exactly admin_set
      end
    end
  end

  describe '#on_behalf_of' do
    it 'can set a proxy deposit target' do
      expect { work.on_behalf_of = 'moomin@example.com' }
        .to change { work.on_behalf_of }
        .to eq 'moomin@example.com'
    end
  end

  describe '#proxy_depositor' do
    it 'can set a proxy deposit source' do
      expect { work.proxy_depositor = 'snufkin@example.com' }
        .to change { work.proxy_depositor }
        .to eq 'snufkin@example.com'
    end
  end

  describe '#state' do
    it 'accepts URIS' do
      uri = RDF::URI('http://example.com/ns/moomin_state')

      expect { work.state = uri}
        .to change { work.state }
        .to uri
    end
  end
end

RSpec.shared_examples 'a Hyrax::FileSet', valkyrie_adapter: :test_adapter do
  subject(:fileset)   { described_class.new }
  let(:adapter)       { Valkyrie::MetadataAdapter.find(:test_adapter) }
  let(:persister)     { adapter.persister }
  let(:query_service) { adapter.query_service }

  it_behaves_like 'a Hyrax::Resource'
  it_behaves_like 'a model with core metadata'
  it_behaves_like 'a model with basic metadata'

  describe '#class' do
    subject(:klass) { fileset.class }

    it { is_expected.not_to be_collection }
    it { is_expected.not_to be_file }
    it { is_expected.to be_file_set }
    it { is_expected.not_to be_pcdm_collection }
    it { is_expected.to be_pcdm_object }
    it { is_expected.not_to be_work }
  end

  describe 'files' do
    it 'has empty file_ids by default' do
      expect(fileset.file_ids).to be_empty
    end

    it 'has empty files by default' do
      expect(query_service.custom_queries.find_files(file_set: fileset)).to be_empty
    end

    context 'with files' do
      let(:original_file) { FactoryBot.valkyrie_create :hyrax_file_metadata, :original_file }
      let(:thumbnail) { FactoryBot.valkyrie_create :hyrax_file_metadata, :thumbnail }
      let(:extracted_text) { FactoryBot.valkyrie_create :hyrax_file_metadata, :extracted_text }
      let(:files) { [original_file, thumbnail, extracted_text] }
      let(:file_ids) { files.map(&:id) }

      before { fileset.file_ids = file_ids }

      it 'has file_ids' do
        expect(fileset.file_ids).to eq file_ids
      end

      it 'has a representative_id' do
        expect(fileset.representative_id).to eq fileset.id
      end

      it 'can query files' do
        expect(query_service.custom_queries.find_files(file_set: fileset)).to eq files
      end

      it 'can not have the same file multiple times' do
        expect { fileset.file_ids << file_ids.first }
          .not_to change { query_service.custom_queries.find_files(file_set: fileset) }
      end

      it 'returns an original_file' do
        expect(fileset.original_file).to eq original_file
        expect(fileset.original_file_id).to eq original_file.id
      end

      it 'returns a thumbnail' do
        expect(fileset.thumbnail).to eq thumbnail
        expect(fileset.thumbnail_id).to eq thumbnail.id
      end

      it 'returns an extracted_text' do
        expect(fileset.extracted_text).to eq extracted_text
        expect(fileset.extracted_text_id).to eq extracted_text.id
      end

      context 'with simulated original file' do
        let(:file_metadata_double) { double("Fake Hyrax::FileMetadata", id: SecureRandom.uuid, file_identifier: "versiondisk://#{Rails.root.join / 'tmp' / 'test_adapter_uploads'}/#{SecureRandom.uuid}", versions: [file_double]) }
        let(:file_double) { double("Fake Valkyrie::StorageAdapter::File", id: SecureRandom.uuid, version_id: SecureRandom.uuid)}

        before do
          allow(fileset).to receive(:original_file).and_return(file_metadata_double)
          fileset.id = Valkyrie::ID.new(SecureRandom.uuid)
        end

        it 'returns a iiif_id with matching ids' do
          expect(fileset.iiif_id).to eq "#{fileset.id}/files/#{fileset.original_file_id}/#{Digest::MD5.hexdigest(file_double.version_id)}"
        end
      end
    end
  end
end
