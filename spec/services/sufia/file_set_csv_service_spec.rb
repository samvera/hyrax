describe Sufia::FileSetCSVService do
  let(:mock_file) do
    double('original_file',
           file_size: '',
           height: '',
           width: '',
           format_label: '',
           digest: '',
           mime_type: 'application/pdf')
  end
  let(:file) do
    FileSet.new(id: '123abc', title: ['My Title'], creator: ['Von, Creator'],
                resource_type: ['Book', 'Other'], rights: ['Mine']) do |f|
      f.apply_depositor_metadata('jilluser@example.com')
    end
  end
  let(:solr_document) { SolrDocument.new(file.to_solr) }

  before do
    allow(file).to receive(:original_file).and_return(mock_file)
  end

  context "when using the defaults" do
    let(:csv_service) { described_class.new(solr_document) }

    describe "csv" do
      subject { csv_service.csv }

      it { is_expected.to eq "123abc,My Title,jilluser@example.com,\"Von, Creator\",restricted,Book|Other,Mine,pdf\n" }
      it "parses as valid csv" do
        expect(CSV.parse(subject)).to eq([["123abc", "My Title", "jilluser@example.com", "Von, Creator", "restricted", "Book|Other", "Mine", "pdf"]])
      end
    end

    describe "csv_header" do
      subject { csv_service.csv_header }
      it { is_expected.to eq "id,title,depositor,creator,visibility,resource_type,rights,file_format\n" }
    end
  end

  context "when specifying terms" do
    let(:csv_service) { described_class.new(file, [:id, :title, :resource_type]) }
    describe "csv" do
      subject { csv_service.csv }
      it { is_expected.to eq "123abc,My Title,Book|Other\n" }
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

      it { is_expected.to eq "123abc,My Title,jilluser@example.com,\"Von, Creator\",restricted,Book&&Other,Mine,pdf\n" }
    end

    describe "csv_header" do
      subject { csv_service.csv_header }
      it { is_expected.to eq "id,title,depositor,creator,visibility,resource_type,rights,file_format\n" }
    end
  end

  context "when specifying terms and separator" do
    let(:csv_service) { described_class.new(file, [:id, :title, :resource_type], '*$*') }
    describe "csv" do
      subject { csv_service.csv }
      it { is_expected.to eq "123abc,My Title,Book*$*Other\n" }
    end
    describe "csv_header" do
      subject { csv_service.csv_header }
      it { is_expected.to eq "id,title,resource_type\n" }
    end
  end
end
