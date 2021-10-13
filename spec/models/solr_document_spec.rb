# frozen_string_literal: true
RSpec.describe ::SolrDocument, type: :model do
  subject(:document) { described_class.new(attributes) }
  let(:attributes) { {} }

  describe "#itemtype" do
    let(:attributes) { { resource_type_tesim: ['Article'] } }

    it "delegates to the Hyrax::ResourceTypesService" do
      expect(Hyrax::ResourceTypesService).to receive(:microdata_type).with('Article')
      subject
    end
    subject { document.itemtype }

    it { is_expected.to eq 'http://schema.org/Article' }

    context 'with no resource_type' do
      let(:attributes) { {} }

      it { is_expected.to eq 'http://schema.org/CreativeWork' }
    end
  end

  describe "date_uploaded" do
    let(:attributes) { { 'date_uploaded_dtsi' => '2013-03-14T00:00:00Z' } }

    subject { document.date_uploaded }

    it { is_expected.to eq Date.parse('2013-03-14') }

    context "when an invalid type is provided" do
      let(:attributes) { { 'date_uploaded_dtsi' => 'Test' } }

      it "logs parse errors" do
        expect(Hyrax.logger).to receive(:info).with(/Unable to parse date.*/)
        subject
      end
    end
  end

  describe "rights_statement" do
    let(:attributes) { { 'rights_statement_tesim' => ['A rights statement'] } }

    it "responds to rights_statement" do
      expect(document).to respond_to(:rights_statement)
    end
    it "returns the proper data" do
      expect(document.rights_statement).to eq ['A rights statement']
    end
  end

  describe "create_date" do
    let(:attributes) { { 'system_create_dtsi' => '2013-03-14T00:00:00Z' } }

    subject { document.create_date }

    it { is_expected.to eq Date.parse('2013-03-14') }

    context "when an invalid type is provided" do
      let(:attributes) { { 'system_create_dtsi' => 'Test' } }

      it "logs parse errors" do
        expect(Hyrax.logger).to receive(:info).with(/Unable to parse date.*/)
        subject
      end
    end
  end

  describe "resource_type" do
    let(:attributes) { { 'resource_type_tesim' => ['Image'] } }

    subject { document.resource_type }

    it { is_expected.to eq ['Image'] }
  end

  describe "thumbnail_path" do
    let(:attributes) { { 'thumbnail_path_ss' => ['/foo/bar'] } }

    subject { document.thumbnail_path }

    it { is_expected.to eq '/foo/bar' }
  end

  describe '#to_param' do
    let(:id) { '1v53kn56d' }
    let(:attributes) { { id: id } }

    subject { document.to_param }

    it { is_expected.to eq id }
  end

  describe "#suppressed?" do
    let(:attributes) { { 'suppressed_bsi' => suppressed_value } }

    context 'when true' do
      let(:suppressed_value) { true }

      it { is_expected.to be_suppressed }
    end
    context 'when false' do
      let(:suppressed_value) { false }

      it { is_expected.not_to be_suppressed }
    end
  end
  describe "document types" do
    class Mimes
      include Hydra::Works::MimeTypes
    end

    Mimes.office_document_mime_types.each do |type|
      context "when mime-type is #{type}" do
        let(:attributes) { { 'mime_type_ssi' => type } }

        it { is_expected.to be_office_document }
      end
    end

    Mimes.video_mime_types.each do |type|
      context "when mime-type is #{type}" do
        let(:attributes) { { 'mime_type_ssi' => type } }

        it { is_expected.to be_video }
      end
    end
  end

  describe '#collection_ids' do
    subject { document.collection_ids }

    context 'when the object belongs to collections' do
      let(:attributes) do
        { id: '123',
          title_tesim: ['A generic work'],
          collection_ids_tesim: ['123', '456', '789'] }
      end

      it { is_expected.to eq ['123', '456', '789'] }
    end

    context 'when the object does not belong to any collections' do
      let(:attributes) do
        { id: '123',
          title_tesim: ['A generic work'] }
      end

      it { is_expected.to eq [] }
    end
  end

  describe "#height" do
    let(:attributes) { { height_is: '444' } }

    subject { document.height }

    it { is_expected.to eq '444' }
  end

  describe "#width" do
    let(:attributes) { { width_is: '555' } }

    subject { document.width }

    it { is_expected.to eq '555' }
  end

  context "when exporting in endnote format" do
    let(:attributes) { { id: "1234" } }

    subject { document.endnote_filename }

    it { is_expected.to eq("1234.endnote") }
  end

  describe "#admin_set?" do
    let(:attributes) { { 'has_model_ssim' => 'AdminSet' } }

    it { is_expected.to be_admin_set }
  end

  describe "#collection?" do
    let(:attributes) { { 'has_model_ssim' => 'Collection' } }

    it { is_expected.to be_collection }
  end

  describe "#work?" do
    let(:attributes) { { 'has_model_ssim' => 'GenericWork' } }

    it { is_expected.to be_work }
  end

  describe "#collection_type_gid?" do
    let(:attributes) { { 'collection_type_gid_ssim' => 'gid://internal/hyrax-collectiontype/5' } }

    subject { document.collection_type_gid }

    it { is_expected.to eq 'gid://internal/hyrax-collectiontype/5' }
  end
end
