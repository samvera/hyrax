require 'spec_helper'

describe CurationConcerns::WorkIndexer do
  # TODO: file_set_ids returns an empty set unless you persist the work
  let(:user) { create(:user) }
  let(:service) { described_class.new(work) }
  subject(:solr_document) { service.generate_solr_document }

  context "with child works" do
    let!(:work) { create(:work_with_one_file, user: user) }
    let!(:child_work) { create(:generic_work, user: user) }
    let(:file) { work.file_sets.first }

    before do
      work.works << child_work
      allow(CurationConcerns::ThumbnailPathService).to receive(:call).and_return("/downloads/#{file.id}?file=thumbnail")
      work.representative_id = file.id
      work.thumbnail_id = file.id
    end

    it 'indexes member work and file_set ids' do
      expect(solr_document['member_ids_ssim']).to eq work.member_ids
      expect(solr_document['generic_type_sim']).to eq ['Work']
      expect(solr_document.fetch('thumbnail_path_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
      expect(subject.fetch('hasRelatedImage_ssim').first).to eq file.id
      expect(subject.fetch('hasRelatedMediaFragment_ssim').first).to eq file.id
    end

    context "when thumbnail_field is configured" do
      before do
        service.thumbnail_field = 'thumbnail_url_ss'
      end
      it "uses the configured field" do
        expect(solr_document.fetch('thumbnail_url_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
      end
    end
  end

  context "the object status" do
    let(:work) { build(:generic_work) }
    context "when suppressed" do
      before { allow(work).to receive(:suppressed?).and_return(true) }

      it "indexed the suppressed field" do
        expect(solr_document.fetch('suppressed_bsi')).to be true
      end
    end

    context "when not suppressed" do
      it "indexed the suppressed field" do
        expect(solr_document.fetch('suppressed_bsi')).to be false
      end
    end
  end
end
