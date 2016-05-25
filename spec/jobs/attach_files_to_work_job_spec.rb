describe AttachFilesToWorkJob do
  context "happy path" do
    let(:file1) { File.open(fixture_path + '/world.png') }
    let(:file2) { File.open(fixture_path + '/image.jp2') }
    let(:uploaded_file1) { Sufia::UploadedFile.create(file: file1) }
    let(:uploaded_file2) { Sufia::UploadedFile.create(file: file2) }
    let(:generic_work) { create(:public_generic_work) }

    context "with uploaded files on the filesystem" do
      it "attaches files, copies visibility and updates the uploaded files" do
        expect(CharacterizeJob).to receive(:perform_later).twice
        described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2])
        generic_work.reload
        expect(generic_work.file_sets.count).to eq 2
        expect(generic_work.file_sets.map(&:visibility)).to all(eq 'open')
        expect(uploaded_file1.reload.file_set_uri).not_to be_nil
      end
    end

    context "with uploaded files in fog" do
      let(:fog_file) { CarrierWave::Storage::Fog::File.new }
      before do
        module CarrierWave::Storage
          module Fog
            class File
            end
          end
        end
        allow(uploaded_file1.file).to receive(:file).and_return(fog_file)
        allow(uploaded_file2.file).to receive(:file).and_return(fog_file)
      end

      after do
        CarrierWave::Storage.send(:remove_const, :Fog)
      end

      it 'creates ImportUrlJobs' do
        expect(ImportUrlJob).to receive(:perform_later).twice
        described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2])
        generic_work.reload
        expect(generic_work.file_sets.count).to eq 2
        expect(generic_work.file_sets.map(&:visibility)).to all(eq 'open')
        expect(uploaded_file1.reload.file_set_uri).not_to be_nil
      end
    end
  end
end
