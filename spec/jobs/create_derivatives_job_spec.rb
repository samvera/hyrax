RSpec.describe CreateDerivativesJob do
  around do |example|
    ffmpeg_enabled = Hyrax.config.enable_ffmpeg
    Hyrax.config.enable_ffmpeg = true
    example.run
    Hyrax.config.enable_ffmpeg = ffmpeg_enabled
  end

  before do
    # the default characterization service has image/tiff hardcoded
    file_set.original_file.mime_type = mime_type
  end

  let(:file_set) { create_for_repository(:file_set, content: content) }
  let(:file_id) do
    file_set.member_ids.first
  end

  context "with an audio file" do
    let(:file_set) { create_for_repository(:file_set, content: content) }
    let(:content) { fixture_file_upload('piano_note.wav', mime_type) }
    let(:mime_type) { 'audio/x-wav' }
    let(:reloaded) { double('the reloaded file set', id: file_set.id, parent: parent) }
    let(:parent) { nil }
    let(:solr_persister) { instance_double(Valkyrie::Persistence::Solr::Persister) }

    before do
      allow(Hyrax::Queries).to receive(:find_by).and_call_original
      allow(Valkyrie::MetadataAdapter.find(:index_solr)).to receive(:persister).and_return(solr_persister)
      expect(Hyrax::Queries).to receive(:find_by).with(id: file_set.id).and_return(reloaded)
      expect(solr_persister).to receive(:save).with(resource: reloaded)
    end

    context "with a file name" do
      it 'calls create_derivatives and save on a file set' do
        expect(Hydra::Derivatives::AudioDerivatives).to receive(:create)
        described_class.perform_now(file_set, file_id)
      end
    end

    context 'with a parent object' do
      before do
        # Stub out the actual derivative creation
        allow(file_set).to receive(:create_derivatives)
      end

      context 'when the file_set is the thumbnail of the parent' do
        let(:parent) { GenericWork.new(thumbnail_id: file_set.id) }

        it 'updates the index of the parent object' do
          expect(solr_persister).to receive(:save).with(resource: parent)
          described_class.perform_now(file_set, file_id)
        end
      end

      context "when the file_set isn't the parent's thumbnail" do
        let(:parent) { GenericWork.new }

        it "doesn't update the parent's index" do
          expect(solr_persister).not_to receive(:save).with(resource: parent)
          described_class.perform_now(file_set, file_id)
        end
      end
    end
  end

  context "with a pdf file" do
    let(:content) { fixture_file_upload('hyrax/hyrax_test4.pdf', 'application/pdf') }

    let(:mime_type) { 'application/pdf' }

    it "runs a full text extract" do
      expect(Hydra::Derivatives::PdfDerivatives).to receive(:create)
        .with(Pathname, outputs: [{ label: :thumbnail,
                                    format: 'jpg',
                                    size: '338x493',
                                    url: String,
                                    layer: 0 }])
      expect(Hydra::Derivatives::FullTextExtract).to receive(:create)
        .with(Pathname, outputs: [{ url: String, container: "extracted_text" }])
      described_class.perform_now(file_set, file_id)
    end
  end
end
