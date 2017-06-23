RSpec.describe JobIoWrapper, type: :model do
  let(:user) { build(:user) }
  let(:path) { fixture_path + '/world.png' }
  let(:file_set_id) { 'bn999672v' }
  let(:file_set) { instance_double(FileSet, id: file_set_id, uri: 'http://127.0.0.1/rest/fake/bn/99/96/72/bn999672v') }
  let(:uploaded_file) { Hyrax::UploadedFile.new(user: user, file_set_uri: file_set.uri, file: File.open(path)) }
  let(:args) {  { file_set_id: file_set_id, user: user, path: path } }
  subject { described_class.new(args) }

  it 'requires attributes' do
    expect { described_class.create! }.to raise_error ActiveRecord::RecordInvalid
    expect { described_class.create!(file_set_id: file_set_id, path: path) }.to raise_error ActiveRecord::RecordInvalid
    expect { described_class.create!(file_set_id: file_set_id, user: user) }.to raise_error ActiveRecord::RecordInvalid
    expect { subject.save! }.not_to raise_error
  end

  context 'with uploaded_file' do
    let(:args) { { file_set_id: file_set_id, user: user, uploaded_file: uploaded_file } }
    it 'accepted in leiu of path' do
      expect { subject.save! }.not_to raise_error
    end
    it 'accepted along with path' do
      expect { described_class.create!(args.merge(path: path)) }.not_to raise_error
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

  describe '#file_actor' do
    let(:file_actor) { Hyrax::Actors::FileActor.new(file_set, subject.relation, user) }
    it 'produces an appropriate FileActor' do
      allow(subject).to receive(:file_set).and_return(file_set)
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
end
