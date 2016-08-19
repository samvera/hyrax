require 'spec_helper'

describe CurationConcerns::FileSetPresenter do
  let(:attributes) { { "title_tesim" => ["foo bar"],
                       "human_readable_type_tesim" => ["File Set"],
                       "mime_type_ssi" => 'image/jpeg',
                       'label_tesim' => ['one', 'two'],
                       "has_model_ssim" => ["FileSet"] } }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_document, ability) }

  describe "#to_s" do
    subject { presenter.to_s }
    it { is_expected.to eq 'foo bar' }
  end

  describe "#human_readable_type" do
    subject { presenter.human_readable_type }
    it { is_expected.to eq 'File Set' }
  end

  describe "#model_name" do
    subject { presenter.model_name }
    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe "#to_partial_path" do
    subject { presenter.to_partial_path }
    it { is_expected.to eq 'file_sets/file_set' }
  end

  describe "office_document?" do
    subject { presenter.office_document? }
    it { is_expected.to be false }
  end

  describe "has?" do
    subject { presenter.has?('thumbnail_path_ss') }
    it { is_expected.to be false }
  end

  describe "first" do
    subject { presenter.first('human_readable_type_tesim') }
    it { is_expected.to eq 'File Set' }
  end

  describe "properties delegated to solr_document" do
    let(:solr_properties) do
      ["date_uploaded", "depositor", "keyword", "title_or_label",
       "contributor", "creator", "title", "description", "publisher",
       "subject", "language", "rights", "format_label", "file_size",
       "height", "width", "filename", "well_formed", "page_count",
       "file_title", "last_modified", "original_checksum", "mime_type",
       "duration", "sample_rate"]
    end
    it "delegates to the solr_document" do
      solr_properties.each do |property|
        expect(solr_document).to receive(property.to_sym)
        presenter.send(property)
      end
    end
  end

  describe "fetch" do
    it "delegates to the solr_document" do
      expect(solr_document).to receive(:fetch).and_call_original
      expect(presenter.fetch("has_model_ssim")).to eq ["FileSet"]
    end
  end

  describe "#link_name" do
    subject { presenter.link_name }
    context "when it's readable" do
      before { allow(ability).to receive(:can?).and_return(true) }
      it { is_expected.to eq 'one' }
    end

    context "when it's not readable" do
      before { allow(ability).to receive(:can?).and_return(false) }
      it { is_expected.to eq 'File' }
    end
  end

  describe "#single_use_links" do
    let!(:show_link)     { create(:show_link, itemId: presenter.id) }
    let!(:download_link) { create(:download_link, itemId: presenter.id) }
    subject { presenter.single_use_links }
    it { is_expected.to include(CurationConcerns::SingleUseLinkPresenter) }
  end

  describe "characterization" do
    describe "#characterization_metadata" do
      subject { presenter.characterization_metadata }
      it { is_expected.to be_kind_of(Hash) }

      it "only has set attributes are in the metadata" do
        expect(subject[:height]).to be_blank
        expect(subject[:page_count]).to be_blank
      end

      context "when height is set" do
        let(:attributes) { { height_is: '444' } }
        it "only has set attributes are in the metadata" do
          expect(subject[:height]).not_to be_blank
          expect(subject[:page_count]).to be_blank
        end
      end
    end

    describe "#characterized?" do
      subject { presenter }
      context "when attributes are not set" do
        let(:attributes) { {} }
        it { is_expected.not_to be_characterized }
      end

      context "when height is set" do
        let(:attributes) { { height_is: '444' } }
        it { is_expected.to be_characterized }
      end

      context "when file_format is set" do
        let(:attributes) { { file_format_tesim: ['format'] } }
        it { is_expected.to be_characterized }
      end
    end

    describe "#label_for_term" do
      subject { presenter.label_for_term(:titleized_key) }
      it { is_expected.to eq("Titleized Key") }
    end

    describe "with additional characterization metadata" do
      let(:additional_metadata) do
        {
          foo: ["bar"],
          fud: ["bars", "cars"]
        }
      end

      before { allow(presenter).to receive(:additional_characterization_metadata).and_return(additional_metadata) }
      subject { presenter }

      specify do
        expect(subject).to be_characterized
        expect(subject.characterization_metadata[:foo]).to contain_exactly("bar")
        expect(subject.characterization_metadata[:fud]).to contain_exactly("bars", "cars")
      end
    end

    describe "characterization values" do
      before { allow(presenter).to receive(:characterization_metadata).and_return(mock_metadata) }

      context "with a limited set of short values" do
        let(:mock_metadata) { { term: ["asdf", "qwer"] } }
        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }
          it { is_expected.to contain_exactly("asdf", "qwer") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }
          it { is_expected.to be_empty }
        end
      end

      context "with a value set exceeding the configured amount" do
        let(:mock_metadata) { { term: ["1", "2", "3", "4", "5", "6", "7", "8"] } }
        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }
          it { is_expected.to contain_exactly("1", "2", "3", "4", "5") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }
          it { is_expected.to contain_exactly("6", "7", "8") }
        end
      end

      context "with values exceeding 250 characters" do
        let(:mock_metadata) { { term: [("a" * 251), "2", "3", "4", "5", "6", ("b" * 251)] } }
        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }
          it { is_expected.to contain_exactly(("a" * 247) + "...", "2", "3", "4", "5") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }
          it { is_expected.to contain_exactly("6", (("b" * 247) + "...")) }
        end
      end

      context "with a string as a value" do
        let(:mock_metadata) { { term: "string" } }
        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }
          it { is_expected.to contain_exactly("string") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }
          it { is_expected.to be_empty }
        end
      end

      context "with an integer as a value" do
        let(:mock_metadata) { { term: 1440 } }
        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }
          it { is_expected.to contain_exactly("1440") }
        end
      end
    end
  end
end
