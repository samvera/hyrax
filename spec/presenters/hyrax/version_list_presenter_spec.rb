# frozen_string_literal: true
RSpec.describe Hyrax::VersionListPresenter do
  let(:resource_version) do
    ActiveFedora::VersionsGraph::ResourceVersion.new.tap do |v|
      v.uri = 'http://example.com/version1'
      v.label = 'version1'
      v.created = '2014-12-09T02:03:18.296Z'
    end
  end

  let(:resource_version2) do
    ActiveFedora::VersionsGraph::ResourceVersion.new.tap do |v|
      v.uri = 'http://example.com/version2'
      v.label = 'version2'
      v.created = '2014-12-19T02:03:18.296Z'
    end
  end

  subject(:enum) { described_class.new([resource_version, resource_version2]) }

  describe ".for" do
    context "with an ActiveFedora::Base" do
      it "gives an empty enumerable" do
        file_set = FactoryBot.create(:file_set)

        expect(described_class.for(file_set: file_set)).to be_none
      end

      it "enumerates over version presenters for original_file" do
        file_set   = FactoryBot.create(:file_set)
        binary     = StringIO.new("hey")
        new_binary = StringIO.new("hey2")

        Hydra::Works::AddFileToFileSet
          .call(file_set, binary, :original_file, versioning: true)
        Hydra::Works::AddFileToFileSet
          .call(file_set, new_binary, :original_file, versioning: true)

        expect(described_class.for(file_set: file_set).count).to eq 2
      end
    end

    context "with a bad argument" do
      it "raises an error" do
        expect { described_class.for(file_set: nil) }
          .to raise_error ArgumentError
      end
    end
  end

  describe "#each" do
    it "yields version_presenters" do
      versions_descending = []

      enum.each do |v|
        expect(v).to be_kind_of Hyrax::VersionPresenter
        versions_descending.push(v.label)
      end

      expect(versions_descending).to eq ['version2', 'version1']
    end
  end
end
