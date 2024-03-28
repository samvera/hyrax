# frozen_string_literal: true
RSpec.describe Hyrax::VersionListPresenter do
  context "for active fedora", :active_fedora do
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

  context "for valkyrie" do
    let(:file) { fixture_file_upload('/world.png', 'image/png') }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, uploaded_files: [FactoryBot.create(:uploaded_file)]) }
    let(:file_set) { query_service.find_members(resource: work).first }
    let(:file_metadata) { query_service.custom_queries.find_files(file_set: file_set).first }
    let(:uploaded) { storage_adapter.find_by(id: file_metadata.file_identifier) }
    let(:query_service) { Hyrax.query_service }
    let(:storage_adapter) { Hyrax.storage_adapter }
    subject(:enum) { described_class.for(file_set: file_set) }
    context "when the file set has no versions" do
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
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
      let(:another_file) { fixture_file_upload('/hyrax_generic_stub.txt') }
      let(:new_version) { storage_adapter.upload_version(id: uploaded.id, file: another_file) }
      before do
        new_version
      end

      describe ".for" do
        it "returns an enumerable with members" do
          expect(enum.count).to eq 2
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
end
