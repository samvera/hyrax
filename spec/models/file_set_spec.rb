# This tests the FileSet model that is inserted into the host app by hyrax:models
# It includes the Hyrax::FileSetBehavior module and nothing else
# So this test covers both the FileSetBehavior module and the generated FileSet model
RSpec.describe FileSet do
  include Hyrax::FactoryHelpers

  let(:user) { create(:user) }
  let(:persister) { Valkyrie.config.metadata_adapter.persister }

  it 'has depositor' do
    subject.depositor = 'tess@example.com'
  end

  context 'when it is initialized' do
    it 'has empty arrays for the properties' do
      expect(subject.title).to eq []
    end
  end

  describe 'visibility' do
    it "does not be changed when it's new" do
      expect(subject).not_to be_visibility_changed
    end
    it 'is changed when it has been changed' do
      subject.visibility = 'open'
      expect(subject).to be_visibility_changed
    end

    it "does not be changed when it's set to its previous value" do
      subject.visibility = 'restricted'
      expect(subject).not_to be_visibility_changed
    end
  end

  describe '#apply_depositor_metadata' do
    before { subject.apply_depositor_metadata('jcoyne') }

    it 'grants edit access and record the depositor' do
      expect(subject.edit_users).to eq ['jcoyne']
      expect(subject.depositor).to eq 'jcoyne'
    end
  end

  describe 'metadata' do
    it 'has descriptive metadata' do
      expect(subject).to respond_to(:relative_path)
      expect(subject).to respond_to(:depositor)
      expect(subject).to respond_to(:related_url)
      expect(subject).to respond_to(:based_near)
      expect(subject).to respond_to(:contributor)
      expect(subject).to respond_to(:creator)
      expect(subject).to respond_to(:title)
      expect(subject).to respond_to(:description)
      expect(subject).to respond_to(:publisher)
      expect(subject).to respond_to(:date_created)
      expect(subject).to respond_to(:date_uploaded)
      expect(subject).to respond_to(:date_modified)
      expect(subject).to respond_to(:subject)
      expect(subject).to respond_to(:language)
      expect(subject).to respond_to(:license)
      expect(subject).to respond_to(:resource_type)
      expect(subject).to respond_to(:identifier)
    end
    it 'has properties from characterization metadata' do
      expect(subject).to respond_to(:format_label)
      expect(subject).to respond_to(:mime_type)
      expect(subject).to respond_to(:file_size)
      expect(subject).to respond_to(:last_modified)
      expect(subject).to respond_to(:filename)
      expect(subject).to respond_to(:original_checksum)
      expect(subject).to respond_to(:well_formed)
      expect(subject).to respond_to(:page_count)
      expect(subject).to respond_to(:file_title)
      expect(subject).to respond_to(:duration)
      expect(subject).to respond_to(:sample_rate)
      # :creator is characterization metadata?
      expect(subject).to respond_to(:creator)
    end

    it 'redefines to_param to make redis keys more recognizable' do
      expect(subject.to_param).to eq subject.id
    end

    describe 'that have been saved' do
      before { subject.apply_depositor_metadata('jcoyne') }

      it 'is able to set values via delegated methods' do
        subject.related_url = ['http://example.org/']
        subject.creator = ['John Doe']
        subject.title = ['New work']
        saved = persister.save(resource: subject)
        f = Hyrax::Queries.find_by(id: saved.id)
        expect(f.related_url).to eq ['http://example.org/']
        expect(f.creator).to eq ['John Doe']
        expect(f.title).to eq ['New work']
      end

      it 'is able to be added to w/o unexpected graph behavior' do
        subject.creator = ['John Doe']
        subject.title = ['New work']
        saved = persister.save(resource: subject)
        f = Hyrax::Queries.find_by(id: saved.id)
        expect(f.creator).to eq ['John Doe']
        expect(f.title).to eq ['New work']
        f.creator = ['Jane Doe']
        f.title += ['Newer work']
        saved = persister.save(resource: f)
        f = Hyrax::Queries.find_by(id: saved.id)
        expect(f.creator).to eq ['Jane Doe']
        # TODO: Is order important?
        expect(f.title).to include('New work')
        expect(f.title).to include('Newer work')
      end
    end
  end

  it 'supports setting and getting the relative_path value' do
    subject.relative_path = 'documents/research/NSF/2010'
    expect(subject.relative_path).to eq 'documents/research/NSF/2010'
  end

  describe 'create_thumbnail' do
    let(:file_set) do
      create_for_repository(:file_set, content: file)
    end
    let(:file) { fixture_file_upload('/countdown.avi', 'video/quicktime') }

    describe 'with a video', if: Hyrax.config.enable_ffmpeg do
      it 'makes a png thumbnail' do
        file_set.create_thumbnail
        expect(file_set.thumbnail.content.size).to eq 4768 # this is a bad test. I just want to show that it did something.
        expect(file_set.thumbnail.mime_type).to eq 'image/png'
      end
    end
  end

  context 'with access control metadata' do
    subject do
      described_class.new
    end

    it 'has read groups writer' do
      subject.read_groups = ['group-2', 'group-3']
      expect(subject.read_groups).to eq ['group-2', 'group-3']
    end
  end

  describe 'public?' do
    context 'when read group is set to public' do
      before { subject.read_groups = ['public'] }

      it { is_expected.to be_public }
    end

    context 'when read group is not set to public' do
      before { subject.read_groups = ['foo'] }
      it { is_expected.not_to be_public }
    end
  end

  describe '#parents' do
    let(:work) { create_for_repository(:work_with_one_file) }

    subject { Hyrax::Queries.find_members(resource: work).first }

    it 'belongs to works' do
      expect(subject.parents.map(&:id)).to eq [work.id]
    end
  end

  describe '#to_s' do
    it 'uses the provided titles' do
      # The title property would return the terms in random order, so stub the behavior:
      subject.title = %w[Hello World]
      expect(subject.to_s).to include 'Hello'
      expect(subject.to_s).to include 'World'
    end

    it 'falls back on label if no titles are given' do
      subject.title = []
      subject.label = 'Spam'
      expect(subject.to_s).to eq('Spam')
    end

    it 'with no label or titles it is "No Title"' do
      subject.title = []
      subject.label = nil
      expect(subject.to_s).to eq('No Title')
    end
  end

  describe 'mime type recognition' do
    let(:mock_file) { mock_file_factory(mime_type: mime_type) }

    before { allow(subject).to receive(:original_file).and_return(mock_file) }

    context '#image?' do
      context 'when image/jp2' do
        let(:mime_type) { 'image/jp2' }

        it { is_expected.to be_image }
      end
      context 'when image/jpg' do
        let(:mime_type) { 'image/jpg' }

        it { is_expected.to be_image }
      end
      context 'when image/png' do
        let(:mime_type) { 'image/png' }

        it { is_expected.to be_image }
      end
      context 'when image/tiff' do
        let(:mime_type) { 'image/tiff' }

        it { is_expected.to be_image }
      end
    end

    describe '#pdf?' do
      let(:mime_type) { 'application/pdf' }

      it { is_expected.to be_pdf }
    end

    describe '#audio?' do
      context 'when x-wave' do
        let(:mime_type) { 'audio/x-wave' }

        it { is_expected.to be_audio }
      end
      context 'when x-wav' do
        let(:mime_type) { 'audio/x-wav' }

        it { is_expected.to be_audio }
      end
      context 'when mpeg' do
        let(:mime_type) { 'audio/mpeg' }

        it { is_expected.to be_audio }
      end
      context 'when mp3' do
        let(:mime_type) { 'audio/mp3' }

        it { is_expected.to be_audio }
      end
      context 'when ogg' do
        let(:mime_type) { 'audio/ogg' }

        it { is_expected.to be_audio }
      end
    end

    describe '#video?' do
      context 'should be true for avi' do
        let(:mime_type) { 'video/avi' }

        it { is_expected.to be_video }
      end

      context 'should be true for webm' do
        let(:mime_type) { 'video/webm' }

        it { is_expected.to be_video }
      end
      context 'should be true for mp4' do
        let(:mime_type) { 'video/mp4' }

        it { is_expected.to be_video }
      end
      context 'should be true for mpeg' do
        let(:mime_type) { 'video/mpeg' }

        it { is_expected.to be_video }
      end
      context 'should be true for quicktime' do
        let(:mime_type) { 'video/quicktime' }

        it { is_expected.to be_video }
      end
      context 'should be true for mxf' do
        let(:mime_type) { 'application/mxf' }

        it { is_expected.to be_video }
      end
    end
  end

  describe "#to_global_id" do
    let(:file_set) { described_class.new(id: '123') }

    subject { file_set.to_global_id }

    it { is_expected.to be_kind_of GlobalID }
  end
end
