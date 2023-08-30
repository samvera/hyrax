# frozen_string_literal: true
RSpec.describe Hyrax::VersionListPresenter do
  let(:file_set) { FactoryBot.create(:file_set) }
  subject(:enum) { described_class.for(file_set: file_set) }

  context "when the file set has no versions" do
    describe ".for" do
      it "returns an enumerable with no members" do
        expect(enum.count).to eq 0
      end
    end

    describe "#each" do
      it "yields nothing" do
        versions_descending = []
        enum.each do |v|
          versions_descending.push(v.label)
        end
        expect(versions_descending).to be_empty
      end
    end

    describe "#empty?" do
      it "is true" do
        expect(enum).to be_empty
      end
    end
  end

  context "when the file set has versions" do
    before do
      binary     = StringIO.new("hey")
      new_binary = StringIO.new("hey2")

      Hydra::Works::AddFileToFileSet
        .call(file_set, binary, :original_file, versioning: true)
      Hydra::Works::AddFileToFileSet
        .call(file_set, new_binary, :original_file, versioning: true)
    end

    describe ".for" do
      it "returns an enumerable with members" do
        expect(enum.count).to eq 2
      end
    end

    describe "#each" do
      it "yields version presenters in order" do
        versions = Hyrax::VersioningService.new(resource: file_set.original_file).versions
        versions_descending = []
        enum.each do |v|
          expect(v).to be_kind_of Hyrax::VersionPresenter
          versions_descending.push(v.uri)
        end
        expect(versions_descending).to eq versions
          .sort { |a, b| b.created <=> a.created }
          .map(&:uri)
      end
    end

    describe "#empty?" do
      it "is false" do
        expect(enum).not_to be_empty
      end
    end
  end

  context "when the file set is bad" do
    let(:file_set) { nil }

    describe ".for" do
      it "raises an error" do
        expect { enum }.to raise_error ArgumentError
      end
    end
  end
end
