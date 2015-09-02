require 'spec_helper'

describe CurationConcerns::ThumbnailPathService do
  subject { described_class.call(object) }

  context "with a GenericFile" do
    let(:object) { GenericFile.new(id: '999', mime_type: mime_type) }
    let(:mime_type) { 'image/jpeg' }
    context "that has a thumbnail" do
      before do
        allow(object).to receive(:thumbnail).and_return(Hydra::PCDM::File.new)
      end
      it { is_expected.to eq '/downloads/999?file=thumbnail' }
    end

    context "that is an audio" do
      let(:mime_type) { 'audio/x-wav' }
      it { is_expected.to eq '/assets/audio.png' }
    end

    context "that has no thumbnail" do
      it { is_expected.to eq '/assets/nope.png' }
    end
  end

  context "with a Work" do
    context "that has a representative" do
      let(:object) { GenericWork.new(representative: '999') }
      let(:representative) { GenericFile.new }
      before do
        allow(representative).to receive(:thumbnail).and_return(Hydra::PCDM::File.new)
        allow(GenericFile).to receive(:load_instance_from_solr).with('999').and_return(representative)
      end

      it { is_expected.to eq '/downloads/999?file=thumbnail' }
    end

    context "that doesn't have a representative" do
      let(:object) { GenericWork.new }
      it { is_expected.to eq '/assets/nope.png' }
    end
  end
end
