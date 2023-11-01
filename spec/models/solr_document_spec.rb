# frozen_string_literal: true
RSpec.describe ::SolrDocument, type: :model do
  subject(:document) { described_class.new(attributes) }
  let(:attributes) { {} }

  describe "#itemtype" do
    let(:attributes) { { resource_type_tesim: ['Article'] } }

    its(:itemtype) { is_expected.to eq 'http://schema.org/Article' }

    it "delegates to the Hyrax::ResourceTypesService" do
      expect(Hyrax::ResourceTypesService).to receive(:microdata_type).with('Article')
      document.itemtype
    end

    context 'with no resource_type' do
      let(:attributes) { {} }

      its(:itemtype) { is_expected.to eq 'http://schema.org/CreativeWork' }
    end
  end

  describe "date_uploaded" do
    let(:attributes) { { 'date_uploaded_dtsi' => '2013-03-14T00:00:00Z' } }

    its(:date_uploaded) { is_expected.to eq Date.parse('2013-03-14') }

    context "when an invalid type is provided" do
      let(:attributes) { { 'date_uploaded_dtsi' => 'Test' } }

      it "logs parse errors" do
        expect(Hyrax.logger).to receive(:info).with(/Unable to parse date.*/)
        document.date_uploaded
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

    its(:create_date) { is_expected.to eq Date.parse('2013-03-14') }

    context "when an invalid type is provided" do
      let(:attributes) { { 'system_create_dtsi' => 'Test' } }

      it "logs parse errors" do
        expect(Hyrax.logger).to receive(:info).with(/Unable to parse date.*/)
        document.create_date
      end
    end
  end

  describe "resource_type" do
    let(:attributes) { { 'resource_type_tesim' => ['Image'] } }

    its(:resource_type) { is_expected.to eq ['Image'] }
  end

  describe "thumbnail_path" do
    let(:attributes) { { 'thumbnail_path_ss' => ['/foo/bar'] } }

    its(:thumbnail_path) { is_expected.to eq '/foo/bar' }
  end

  describe '#to_param' do
    let(:id) { '1v53kn56d' }
    let(:attributes) { { id: id } }

    its(:to_param) { is_expected.to eq id }
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
    context 'when the object belongs to collections' do
      let(:attributes) do
        { id: '123',
          title_tesim: ['A generic work'],
          collection_ids_tesim: ['123', '456', '789'] }
      end

      its(:collection_ids) { is_expected.to eq ['123', '456', '789'] }
    end

    context 'when the object does not belong to any collections' do
      let(:attributes) do
        { id: '123',
          title_tesim: ['A generic work'] }
      end

      its(:collection_ids) { is_expected.to eq [] }
    end
  end

  describe "#height" do
    let(:attributes) { { height_is: '444' } }

    its(:height) { is_expected.to eq '444' }
  end

  describe "#width" do
    let(:attributes) { { width_is: '555' } }

    its(:width) { is_expected.to eq '555' }
  end

  context "when exporting in endnote format" do
    let(:attributes) { { id: "1234" } }

    its(:endnote_filename) { is_expected.to eq("1234.endnote") }
  end

  describe "#admin_set?" do
    let(:attributes) { { 'has_model_ssim' => Hyrax.config.admin_set_model } }

    it { is_expected.to be_admin_set }

    context "with legacy indexed admin set" do
      let(:attributes) { { 'has_model_ssim' => "AdminSet" } }

      it { is_expected.to be_admin_set }
    end
  end

  describe "#collection?" do
    let(:attributes) { { 'has_model_ssim' => Hyrax.config.collection_model } }

    it { is_expected.to be_collection }

    context "with legacy indexed collection" do
      let(:attributes) { { 'has_model_ssim' => "Collection" } }

      it { is_expected.to be_collection }
    end
  end

  describe "#work?" do
    let(:attributes) { { 'has_model_ssim' => 'GenericWork' } }

    it { is_expected.to be_work }
  end

  describe "#collection_type_gid?" do
    let(:attributes) do
      { 'collection_type_gid_ssim' => 'gid://internal/hyrax-collectiontype/5' }
    end

    its(:collection_type_gid) do
      is_expected.to eq 'gid://internal/hyrax-collectiontype/5'
    end
  end
end
