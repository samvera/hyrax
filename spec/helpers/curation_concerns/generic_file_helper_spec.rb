require 'spec_helper'

describe CurationConcerns::GenericFileHelper do
  describe '#media_display' do
    let(:generic_file) { SolrDocument.new(mime_type_tesim: mime_type) }
    let(:mime_type) { 'image/tiff' }

    it "renders a partial" do
      allow(helper).to receive(:media_display_partial).with(generic_file)
        .and_return('curation_concerns/generic_files/media_display/image')
      expect(helper).to receive(:render)
        .with('curation_concerns/generic_files/media_display/image', generic_file: generic_file)
      helper.media_display(generic_file)
    end
  end

  describe '#media_display_partial' do
    subject { helper.media_display_partial(generic_file) }

    let(:generic_file) { SolrDocument.new(mime_type_tesim: mime_type) }

    context "with an image" do
      let(:mime_type) { 'image/tiff' }
      it { is_expected.to eq 'curation_concerns/generic_files/media_display/image' }
    end

    context "with a video" do
      let(:mime_type) { 'video/webm' }
      it { is_expected.to eq 'curation_concerns/generic_files/media_display/video' }
    end

    context "with an audio" do
      let(:mime_type) { 'audio/wav' }
      it { is_expected.to eq 'curation_concerns/generic_files/media_display/audio' }
    end

    context "with a pdf" do
      let(:mime_type) { 'application/pdf' }
      it { is_expected.to eq 'curation_concerns/generic_files/media_display/pdf' }
    end

    context "with a word document" do
      let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
      it { is_expected.to eq 'curation_concerns/generic_files/media_display/office_document' }
    end

    context "with anything else" do
      let(:mime_type) { 'application/binary' }
      it { is_expected.to eq 'curation_concerns/generic_files/media_display/default' }
    end
  end
end
