# frozen_string_literal: true
RSpec.describe Hyrax::FileSetCsvService, :clean_repo do
  let(:file) { create(:uploaded_file, file: File.open('spec/fixtures/sample-file.pdf')) }
  let(:file_metadata) { valkyrie_create(:file_metadata, :original_file, :with_file, file: file, mime_type: 'application/pdf') }
  let(:file_set) do
    valkyrie_create(:hyrax_file_set,
                   depositor: 'jilluser@example.com',
                   title: ['My Title'],
                   creator: ['Von, Creator'],
                   resource_type: ['Book', 'Other'],
                   license: ['Mine'],
                   files: [file_metadata],
                   original_file: file_metadata)
  end
  let(:solr_document) { SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: file_set).to_solr) }

  shared_examples('with expected header text') do
    describe "csv_header" do
      subject { csv_service.csv_header }

      it { is_expected.to eq "id,title,depositor,creator,visibility,resource_type,license,file_format\n" }
    end
  end

  shared_examples('with expected header text (specifying terms)') do
    describe "csv_header" do
      subject { csv_service.csv_header }

      it { is_expected.to eq "id,title,resource_type\n" }
    end
  end

  context "when using the defaults" do
    let(:csv_service) { described_class.new(solr_document) }

    describe "csv" do
      subject { csv_service.csv }

      it { is_expected.to include "#{file_set.id},My Title,jilluser@example.com,\"Von, Creator\",restricted,", "Book", "|", "Other", ",Mine,pdf\n" }
      it "parses as valid csv" do
        expect(::CSV.parse(subject).flatten).to include(file_set.id.to_s, "My Title", "jilluser@example.com", "Von, Creator", "restricted", "Mine", "pdf")
      end
    end

    include_examples 'with expected header text'
  end

  context "when specifying terms" do
    let(:csv_service) { described_class.new(file_set, [:id, :title, :resource_type]) }

    describe "csv" do
      subject { csv_service.csv }

      it { is_expected.to include "#{file_set.id},My Title,", "Book", "|", "Other", "\n" }
    end

    include_examples 'with expected header text (specifying terms)'
  end

  context "when specifying separator" do
    let(:csv_service) { described_class.new(solr_document, nil, '&&') }

    describe "csv" do
      subject { csv_service.csv }

      it { is_expected.to include "#{file_set.id},My Title,jilluser@example.com,\"Von, Creator\",restricted,", "Book", "&&", "Other", ",Mine,pdf\n" }
    end

    include_examples 'with expected header text'
  end

  context "when specifying terms and separator" do
    let(:csv_service) { described_class.new(file_set, [:id, :title, :resource_type], '*$*') }

    describe "csv" do
      subject { csv_service.csv }

      it { is_expected.to include "#{file_set.id},My Title,", "Book", "*$*", "Other", "\n" }
    end

    include_examples 'with expected header text (specifying terms)'
  end
end
