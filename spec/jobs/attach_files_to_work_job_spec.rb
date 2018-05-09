RSpec.describe AttachFilesToWorkJob, perform_enqueued: [AttachFilesToWorkJob] do
  context "happy path" do
    let(:file1) { File.open(fixture_path + '/world.png') }
    let(:file2) { File.open(fixture_path + '/image.jp2') }
    let(:uploaded_file1) { build(:uploaded_file, file: file1) }
    let(:uploaded_file2) { build(:uploaded_file, file: file2) }
    let(:generic_work) { create(:public_generic_work) }
    let(:user) { create(:user) }

    shared_examples 'a file attacher', perform_enqueued: [AttachFilesToWorkJob, IngestJob] do
      it 'attaches files, copies visibility and permissions and updates the uploaded files' do
        expect(CharacterizeJob).to receive(:perform_later).twice
        described_class.perform_now(generic_work, [uploaded_file1, uploaded_file2])
        generic_work.reload
        expect(generic_work.file_sets.count).to eq 2
        expect(generic_work.file_sets.map(&:visibility)).to all(eq 'open')
        expect(uploaded_file1.reload.file_set_uri).not_to be_nil
        expect(ImportUrlJob).not_to have_been_enqueued
      end
    end

    context "with uploaded files on the filesystem" do
      before do
        generic_work.permissions.build(name: 'userz@bbb.ddd', type: 'person', access: 'edit')
        generic_work.save
      end
      it_behaves_like 'a file attacher' do
        it 'records the depositor(s) in edit_users' do
          expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([generic_work.depositor, 'userz@bbb.ddd']))
        end
      end
    end

    context "with uploaded files at remote URLs" do
      let(:url1) { 'https://example.com/my/img.png' }
      let(:url2) { URI('https://example.com/other/img.png') }
      let(:fog_file1) { double(CarrierWave::Storage::Abstract, url: url1) }
      let(:fog_file2) { double(CarrierWave::Storage::Abstract, url: url2) }

      before do
        allow(uploaded_file1.file).to receive(:file).and_return(fog_file1)
        allow(uploaded_file2.file).to receive(:file).and_return(fog_file2)
      end

      it_behaves_like 'a file attacher'
    end

    context "deposited on behalf of another user" do
      before do
        generic_work.on_behalf_of = user.user_key
        generic_work.save
      end
      it_behaves_like 'a file attacher' do
        it 'records the depositor(s) in edit_users' do
          expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([user.user_key]))
        end
      end
    end

    context "deposited as 'Yourself' selected in on behalf of list" do
      before do
        generic_work.on_behalf_of = ''
        generic_work.save
      end
      it_behaves_like 'a file attacher' do
        it 'records the depositor(s) in edit_users' do
          expect(generic_work.file_sets.map(&:edit_users)).to all(match_array([generic_work.depositor]))
        end
      end
    end
  end
end
