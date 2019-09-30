RSpec.describe CharacterizeJob do
  [true, false].each do |test_valkyrie|
    context "when test_valkyrie is #{test_valkyrie}" do
      before do
        Hydra::Works::AddFileToFileSet.call(af_file_set,
                                            File.open(fixture_path + '/world.png'),
                                            :original_file)
        allow(ValkyrieTransitionHelper).to receive(:to_active_fedora).with(any_args).and_return(af_file_set)
        allow(FileSet).to receive(:find).with(file_set_id).and_return(af_file_set)
        allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
        allow(CreateDerivativesJob).to receive(:perform_later).with(af_file_set, file_id, filename)
      end

      let(:file_set_id) { af_file_set.id }
      let(:af_file_set) { create(:file_set) }
      let(:valk_file_set) { af_file_set.valkyrie_resource }
      let(:file_set) { test_valkyrie ? valk_file_set : af_file_set }

      let(:file_id) { file.id }
      let(:file) { af_file_set.original_file }
      let(:filename) do
        Rails.root.join('tmp', 'uploads',
                        file_set_id[0..1], file_set_id[2..3], file_set_id[4..5], file_set_id[6..7],
                        file_set_id, 'world.png').to_s
      end
      let(:valk_file_ids) { [Valkyrie::ID.new(file_id)] }

      context 'with valid filepath param' do
        let(:filename) { File.join(fixture_path, 'world.png') }

        it 'skips Hyrax::WorkingDirectory' do
          expect(Hyrax::WorkingDirectory).not_to receive(:find_or_retrieve)
          expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
          described_class.perform_now(file_set, file_id, filename)
        end
      end

      context 'when the characterization proxy content is present' do
        it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
          expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
          expect(file).to receive(:save!)
          expect(af_file_set).to receive(:update_index)
          expect(CreateDerivativesJob).to receive(:perform_later).with(af_file_set, file_id, filename)
          described_class.perform_now(file_set, file_id)
        end
      end

      context 'when the characterization proxy content is absent' do
        before { allow(af_file_set).to receive(:characterization_proxy?).and_return(false) }
        it 'raises an error' do
          expect { described_class.perform_now(file_set, file_id) }.to raise_error(StandardError, /original_file was not found/)
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
          described_class.perform_now(file_set, file_id)
        end
      end
    end
  end
end
