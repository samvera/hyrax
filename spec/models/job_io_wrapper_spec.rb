# frozen_string_literal: true
RSpec.describe JobIoWrapper, :active_fedora, type: :model do
  let(:user) { build(:user) }
  let(:path) { fixture_path + '/world.png' }
  let(:file_set_id) { 'bn999672v' }
  let(:file_set) { instance_double(FileSet, id: file_set_id, uri: 'http://127.0.0.1/rest/fake/bn/99/96/72/bn999672v') }
  let(:args) { { file_set_id: file_set_id, user: user, path: path } }

  subject(:wrapper) { described_class.new(args) }

  it 'requires attributes' do
    expect { described_class.create! }.to raise_error ActiveRecord::RecordInvalid
    expect { described_class.create!(file_set_id: file_set_id, path: path) }.to raise_error ActiveRecord::RecordInvalid
    expect { described_class.create!(file_set_id: file_set_id, user: user) }.to raise_error ActiveRecord::RecordInvalid
    expect { subject.save! }.not_to raise_error
  end

  describe '.create_with_wrapped_params!' do
    let(:local_file) { File.open(path) }
    let(:relation) { :remastered }

    subject { described_class.create_with_varied_file_handling!(user: user, file_set: file_set, file: file, relation: relation) }

    context 'with Rack::Test::UploadedFile' do
      let(:file) { Rack::Test::UploadedFile.new(path, 'image/png') }

      it 'creates a JobIoWrapper' do
        expected_create_args = { user: user, relation: relation.to_s, file_set_id: file_set.id, path: file.path, original_name: 'world.png' }
        expect(described_class).to receive(:create!).with(expected_create_args)
        subject
      end
    end

    context 'with ::File' do
      let(:file) { local_file }

      it 'creates a JobIoWrapper' do
        expected_create_args = { user: user, relation: relation.to_s, file_set_id: file_set.id, path: file.path }
        expect(described_class).to receive(:create!).with(expected_create_args)
        subject
      end
    end

    context 'with Hyrax::UploadedFile' do
      let(:file) { Hyrax::UploadedFile.new(user: user, file_set_uri: file_set.uri, file: local_file) }

      it 'creates a JobIoWrapper' do
        expected_create_args = { user: user, relation: relation.to_s, file_set_id: file_set.id, uploaded_file: file, path: file.uploader.path }
        expect(described_class).to receive(:create!).with(expected_create_args)
        subject
      end
    end
  end

  describe 'uploaded_file' do
    let(:other_path) { fixture_path + '/image.jpg' }
    let(:uploaded_file) { Hyrax::UploadedFile.new(user: user, file_set_uri: file_set.uri, file: File.new(other_path)) }

    # context 'path only' is the rest of this file

    context 'in leiu of path' do
      let(:args) { { file_set_id: file_set_id, user: user, uploaded_file: uploaded_file } }

      it 'validates and persists' do
        expect { subject.save! }.not_to raise_error
      end
      it '#read routes to the uploaded_file' do
        expect(subject).to receive(:file_from_uploaded_file!).and_call_original
        subject.read
      end
      it '#mime_type and #original_name draw from the uploaded_file' do
        expect(subject.mime_type).to eq('image/jpeg')
        expect(subject.original_name).to eq('image.jpg')
      end
    end

    context 'along with path (on shared filesystem)' do
      let(:args) { { file_set_id: file_set_id, user: user, uploaded_file: uploaded_file, path: path } }

      it 'validates and persists' do
        expect { subject.save! }.not_to raise_error
      end
      it '#read routes to the path' do
        expect(subject).not_to receive(:file_from_uploaded_file!)
        subject.read
      end
      it '#mime_type and #original_name draw from the uploaded_file' do
        expect(subject.mime_type).to eq('image/jpeg')
        expect(subject.original_name).to eq('image.jpg')
      end
    end

    context 'along with path (independent worker filesystems)' do
      let(:deadpath) { fixture_path + '/some_file_that_does_not_exist.wav' }
      let(:args) { { file_set_id: file_set_id, user: user, uploaded_file: uploaded_file, path: deadpath } }

      it 'validates and persists' do
        expect { subject.save! }.not_to raise_error
      end
      it '#read routes to the uploaded_file' do
        expect(subject).to receive(:file_from_uploaded_file!).and_call_original
        subject.read
      end
      it '#mime_type and #original_name draw from the uploaded_file' do
        expect(subject.mime_type).to eq('image/jpeg')
        expect(subject.original_name).to eq('image.jpg')
      end
    end
  end

  it 'has a #user' do
    expect(subject.user).to eq(user)
    expect(subject.user_id).to eq(user.id)
  end

  describe '#relation' do
    it 'has default value' do
      expect(subject.relation).to eq('original_file')
    end
    it 'accepts new value' do
      subject.relation = 'remastered'
      expect(subject.relation).to eq('remastered')
    end
  end

  describe '#original_name' do
    it 'extracts default value' do
      expect(subject.original_name).to eq('world.png')
    end
    it 'accepts new value' do
      subject.original_name = 'foobar'
      expect(subject.original_name).to eq('foobar')
    end
  end

  describe '#mime_type' do
    it 'extracts default value' do
      expect(subject.mime_type).to eq('image/png')
    end
    it 'accepts new value' do
      subject.mime_type = 'text/plain'
      expect(subject.mime_type).to eq('text/plain')
    end
    it 'uses original_name if set' do
      subject.original_name = '汉字.jpg'
      expect(subject.mime_type).to eq('image/jpeg')
      subject.original_name = 'no_suffix'
      expect(subject.mime_type).to eq('application/octet-stream')
    end
  end

  describe '#size' do
    context 'when file responds to :size' do
      before do
        allow(subject.file).to receive(:respond_to?).with(:size).and_return(true)
        allow(subject.file).to receive(:respond_to?).with(:stat).and_return(false)
        allow(subject.file).to receive(:size).and_return(123)
      end
      it 'returns the size of the file' do
        expect(subject.size).to eq '123'
      end
    end
    context 'when file responds to :stat' do
      before do
        allow(subject.file).to receive(:respond_to?).with(:size).and_return(false)
        allow(subject.file).to receive(:respond_to?).with(:stat).and_return(true)
        allow(subject.file).to receive_message_chain(:stat, :size).and_return(456) # rubocop:disable RSpec/MessageChain
      end
      it 'returns the size of the file' do
        expect(subject.size).to eq '456'
      end
    end
    context 'when file responds to neither :size nor :stat' do
      before do
        allow(subject.file).to receive(:respond_to?).with(:size).and_return(false)
        allow(subject.file).to receive(:respond_to?).with(:stat).and_return(false)
      end
      it 'returns nil' do
        expect(subject.size).to eq nil
      end
    end
  end

  describe '#file_actor' do
    let(:file_actor) { Hyrax::Actors::FileActor.new(file_set, subject.relation, user) }

    it 'produces an appropriate FileActor' do
      allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
      expect(subject.file_actor).to eq(file_actor)
    end
  end

  describe '#read' do
    it 'delivers contents' do
      expect(subject.read).to eq(File.open(path, 'rb').read)
    end
    context 'text file' do
      let(:path) { fixture_path + '/png_fits.xml' }

      it 'delivers contents' do
        expect(subject.read).to eq(File.open(path, 'rb').read)
      end
    end
  end

  describe '#file_set' do
    let(:fileset_id) { 'fileset_id' }
    let!(:fileset) { create(:file_set, id: fileset_id) }
    before { allow(subject).to receive(:file_set_id).and_return(fileset_id) }

    context 'when finding through active fedora' do
      it 'finds the file set using active fedora and returns an instance of an active fedora file set' do
        results = subject.file_set
        expect(results).to be_a_kind_of(FileSet)
        expect(results.id).to eq fileset_id
      end
    end
    context 'when finding through valkyrie' do
      it 'finds the file set through valkyrie and returns an instance of a valkyrie file set resource' do
        results = subject.file_set(use_valkyrie: true)
        expect(results).to be_a_kind_of(Valkyrie::Resource)
        expect(results.id.to_s).to eq fileset_id
      end
    end
  end

  describe '#to_file_metadata' do
    it 'creates and returns file_metadata' do
      expect(subject.to_file_metadata).to be_a_kind_of(Hyrax::FileMetadata)
    end
  end

  describe '#file' do
    xit 'switches between local filepath and CarrierWave file'
  end
end
