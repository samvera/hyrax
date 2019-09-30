RSpec.describe CharacterizeJob do
  [true, false].each do |test_valkyrie|
    context "when test_valkyrie is #{test_valkyrie}" do
  let(:file_set_id) { 'abc12345' }
  let(:filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }
  # let(:af_filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }
  # let(:valk_filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'files', 'picture.png').to_s }
  # let(:filename) { test_valkyrie ? valk_filename : af_filename }
  let(:af_file_set) do
    FileSet.new(id: file_set_id).tap do |fs|
      allow(fs).to receive(:original_file).and_return(file)
      allow(fs).to receive(:update_index)
    end
  end
  let(:valk_file_set) { af_file_set.valkyrie_resource }
  let(:file_set) { test_valkyrie ? valk_file_set : af_file_set }
  let(:file) do
    # af_file_set.file_set.association(:original_file)
    Hydra::PCDM::File.new.tap do |f|
    # Hydra::PCDM::File.new(id: "ab/c1/23/45/abc12345/files/xyp98764").tap do |f|
      f.content = 'foo'
      f.original_name = 'picture.png'
      f.save!
      allow(f).to receive(:save!)
    end
  end
  let(:valk_file_ids) { [Valkyrie::ID.new(file.id)] }

  before do
    allow(FileSet).to receive(:find).with(file_set_id).and_return(af_file_set)
    allow_any_instance_of(FileSet).to receive(:new_record?).and_return(false) if test_valkyrie # rubocop:disable RSpec/AnyInstance
byebug
    allow_any_instance_of(valk_file_set).to receive(:original_file_ids).and_return(valk_file_ids) if test_valkyrie # rubocop:disable RSpec/AnyInstance
    allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
    allow(CreateDerivativesJob).to receive(:perform_later).with(af_file_set, file.id, filename)
  end

  context 'with valid filepath param' do
    let(:filename) { File.join(fixture_path, 'world.png') }

    it 'skips Hyrax::WorkingDirectory' do
      expect(Hyrax::WorkingDirectory).not_to receive(:find_or_retrieve)
      expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      described_class.perform_now(file_set, file.id, filename)
    end
  end

  context 'when the characterization proxy content is present' do
    it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
      expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      expect(file).to receive(:save!)
      expect(af_file_set).to receive(:update_index)
      expect(CreateDerivativesJob).to receive(:perform_later).with(af_file_set, file.id, filename)
      described_class.perform_now(file_set, file.id)
    end
  end

  context 'when the characterization proxy content is absent' do
    before { allow(af_file_set).to receive(:characterization_proxy?).and_return(false) }
    it 'raises an error' do
      expect { described_class.perform_now(file_set, file.id) }.to raise_error(StandardError, /original_file was not found/)
    end
  end

  context "when the file set's work is in a collection" do
    let(:work)       { build(:generic_work) }
    let(:collection) { build(:collection_lw) }

    before do
      allow(af_file_set).to receive(:parent).and_return(work)
      allow(work).to receive(:in_collections).and_return([collection])
    end
    it "reindexes the collection" do
      expect(collection).to receive(:update_index)
      described_class.perform_now(file_set, file.id)
    end
  end
    end
  end
end
