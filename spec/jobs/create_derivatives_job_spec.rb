# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreateDerivativesJob do
  around do |example|
    ffmpeg_enabled = Hyrax.config.enable_ffmpeg
    Hyrax.config.enable_ffmpeg = true
    example.run
    Hyrax.config.enable_ffmpeg = ffmpeg_enabled
  end

  context "with an audio file" do
    let(:id)       { '123' }
    let(:file_set) { FileSet.new }

    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = 'foo'
        f.original_name = 'picture.png'
        f.save!
      end
    end

    before do
      allow(FileSet).to receive(:find).with(id).and_return(file_set)
      allow(file_set).to receive(:id).and_return(id)
      allow(file_set).to receive(:mime_type).and_return('audio/x-wav')
    end

    context "with a file name" do
      it 'calls create_derivatives and save on a file set' do
        expect(Hydra::Derivatives::AudioDerivatives).to receive(:create)
        expect(file_set).to receive(:reload)
        expect(file_set).to receive(:update_index)
        described_class.perform_now(file_set, file.id)
      end
    end

    context 'with a parent object' do
      before do
        allow(file_set).to receive(:parent).and_return(parent)
        # Stub out the actual derivative creation
        allow(file_set).to receive(:create_derivatives)
      end

      context 'when the file_set is the thumbnail of the parent' do
        let(:parent) { GenericWork.new(thumbnail_id: id) }

        it 'updates the index of the parent object' do
          expect(file_set).to receive(:reload)
          expect(parent).to receive(:update_index)
          described_class.perform_now(file_set, file.id)
        end
      end

      context "when the file_set isn't the parent's thumbnail" do
        let(:parent) { GenericWork.new }

        it "doesn't update the parent's index" do
          expect(file_set).to receive(:reload)
          expect(parent).not_to receive(:update_index)
          described_class.perform_now(file_set, file.id)
        end
      end
    end
  end

  context "with a pdf file" do
    let(:file_set) { create(:file_set) }
    let(:params)   { { qt: "search", q: "CutePDF", qf: "all_text_timv" } }

    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = File.open(File.join(fixture_path, "hyrax/hyrax_test4.pdf")).read
        f.original_name = 'test.pdf'
        f.save!
      end
    end

    let(:search_response) do
      Blacklight::Solr::Response.new(
        Blacklight.default_index.connection.get("select", params: params),
        params
      )
    end

    before do
      allow(file_set).to receive(:mime_type).and_return('application/pdf')
      described_class.perform_now(file_set, file.id)
    end

    it "searches the extracted content" do
      expect(search_response.documents.count).to eq(1)
    end
  end
end
