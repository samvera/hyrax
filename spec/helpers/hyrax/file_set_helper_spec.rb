# frozen_string_literal: true
RSpec.describe Hyrax::FileSetHelper do
  describe '#display_media_download_link?' do
    let(:ability)  { double(Ability) }
    let(:file_set) { valkyrie_create(:hyrax_file_set) }

    before do
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    it 'does not allow download when permissions restrict it' do
      allow(ability).to receive(:can?).with(:download, file_set).and_return(false)

      expect(helper.display_media_download_link?(file_set: file_set)).to eq false
    end

    it 'allows download when permissions allow it ' do
      allow(ability).to receive(:can?).with(:download, file_set).and_return(true)

      expect(helper.display_media_download_link?(file_set: file_set)).to eq true
    end

    context 'with a FileSetPresenter' do
      let(:ability) { Ability.new(user) }
      let(:file_set) { valkyrie_create(:hyrax_file_set, :public, depositor: user.user_key) }
      let(:presenter) { Hyrax::FileSetPresenter.new(solr_document, ability) }
      let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: file_set).to_solr) }
      let(:user) { FactoryBot.create(:user) }

      it 'resolves permissions based on the solr document' do
        expect(helper.display_media_download_link?(file_set: presenter))
          .to eq true
      end
    end
  end

  describe '#media_display' do
    let(:file_set) { SolrDocument.new(mime_type_ssi: mime_type) }
    let(:mime_type) { 'image/tiff' }

    before do
      allow(helper).to receive(:media_display_partial).with(file_set)
                                                      .and_return('hyrax/file_sets/media_display/image')
    end

    it "renders a partial" do
      expect(helper).to receive(:render)
        .with('hyrax/file_sets/media_display/image', { file_set: file_set })
      helper.media_display(file_set)
    end

    it "takes options" do
      expect(helper).to receive(:render)
        .with('hyrax/file_sets/media_display/image', { file_set: file_set, transcript_id: '123' })
      helper.media_display(file_set, transcript_id: '123')
    end
  end

  describe '#media_display_partial' do
    subject { helper.media_display_partial(file_set) }

    let(:file_set) { SolrDocument.new(mime_type_ssi: mime_type) }

    context "with an image" do
      let(:mime_type) { 'image/tiff' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/image' }
    end

    context "with a video" do
      let(:mime_type) { 'video/webm' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/video' }
    end

    context "with an audio" do
      let(:mime_type) { 'audio/wav' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/audio' }
    end

    context "with a pdf" do
      let(:mime_type) { 'application/pdf' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/pdf' }
    end

    context "with a word document" do
      let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/office_document' }
    end

    context "with anything else" do
      let(:mime_type) { 'application/binary' }

      it { is_expected.to eq 'hyrax/file_sets/media_display/default' }
    end
  end
end
