# frozen_string_literal: true
RSpec.describe Hyrax::FileSetCsvService do
  let(:mock_file) do
    Hydra::PCDM::File.new
  end
  let(:work) { create(:work, title: ['test title'], creator: ['Von, Creator']) }
  let(:file_set_id) { '123abc456' }
  let(:file) do
    f = create(:file_set, id: file_set_id, title: ['My Title'], creator: ['Von, Creator'],
                          resource_type: ['Book', 'Other'], license: ['Mine'])
    f.apply_depositor_metadata('jilluser@example.com')
    work.ordered_members << f
    work.save!
    f
  end
  let(:solr_document) { SolrDocument.new(file.to_solr) }

  before do
    allow(mock_file).to receive(:mime_type).and_return('application/pdf')
    allow(file).to receive(:resource_type).and_return(['Book', 'Other'])
    allow(file).to receive(:original_file).and_return(mock_file)
  end

  context "when using the defaults" do
    let(:csv_service) { described_class.new(solr_document) }

    describe "csv" do
      subject { csv_service.csv }

      it { is_expected.to eq "#{file_set_id},My Title,jilluser@example.com,\"Von, Creator\",restricted,Book|Other,Mine,pdf\n" }
      it "parses as valid csv" do
        expect(::CSV.parse(subject)).to eq([[file_set_id, "My Title", "jilluser@example.com", "Von, Creator", "restricted", "Book|Other", "Mine", "pdf"]])
      end
    end

    describe "csv_header" do
      subject { csv_service.csv_header }

      it { is_expected.to eq "id,title,depositor,creator,visibility,resource_type,license,file_format\n" }
    end
  end

  context "when specifying terms" do
    let(:csv_service) { described_class.new(file, [:id, :title, :resource_type]) }

    describe "csv" do
      subject { csv_service.csv }

      it { is_expected.to eq "#{file_set_id},My Title,Book|Other\n" }
    end
    describe "csv_header" do
      subject { csv_service.csv_header }

      it { is_expected.to eq "id,title,resource_type\n" }
    end
  end

  context "when specifying separator" do
    let(:csv_service) { described_class.new(solr_document, nil, '&&') }

    describe "csv" do
      subject { csv_service.csv }

      it { is_expected.to eq "#{file_set_id},My Title,jilluser@example.com,\"Von, Creator\",restricted,Book&&Other,Mine,pdf\n" }
    end

    describe "csv_header" do
      subject { csv_service.csv_header }

      it { is_expected.to eq "id,title,depositor,creator,visibility,resource_type,license,file_format\n" }
    end
  end

  context "when specifying terms and separator" do
    let(:csv_service) { described_class.new(file, [:id, :title, :resource_type], '*$*') }

    describe "csv" do
      subject { csv_service.csv }

      it { is_expected.to eq "#{file_set_id},My Title,Book*$*Other\n" }
    end
    describe "csv_header" do
      subject { csv_service.csv_header }

      it { is_expected.to eq "id,title,resource_type\n" }
    end
  end
end
