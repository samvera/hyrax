require 'spec_helper'

describe Sufia::FileSetPresenter do
  let(:solr_document) { SolrDocument.new(file.to_solr) }
  let(:ability) { double "Ability" }
  let(:presenter) { described_class.new(solr_document, ability) }
  let(:file) { build(:file_set, id: '123abc', user: user) }

  describe 'stats_path' do
    let(:user) { double(user_key: 'sarah') }
    it { expect(presenter.stats_path).to eq Sufia::Engine.routes.url_helpers.stats_file_path(id: file) }
  end

  describe '#tweeter' do
    subject { presenter.tweeter }

    context "with a user that can be found" do
      let(:user) { create :user, twitter_handle: 'test' }
      it { is_expected.to eq '@test' }
    end

    context "with a user that doesn't have a twitter handle" do
      let(:user) { create :user, twitter_handle: '' }
      it { is_expected.to eq '@HydraSphere' }
    end

    context "with a user that can't be found" do
      let(:user) { double(user_key: 'sarah') }
      it { is_expected.to eq '@HydraSphere' }
    end
  end

  describe "characterization" do
    let(:user) { double(user_key: 'user') }

    describe "#characterization_metadata" do
      subject { presenter.characterization_metadata }
      it { is_expected.to be_kind_of(Hash) }
    end

    describe "#characterized?" do
      subject { presenter }
      it { is_expected.not_to be_characterized }
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
    end
  end
end
