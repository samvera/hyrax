# frozen_string_literal: true

RSpec.describe Hyrax::FileSetFileService do
  subject(:service) { described_class.new(file_set: file_set) }
  let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

  describe "#primary_file" do
    it "is nil when there are no files" do
      expect(service.primary_file).to be_nil
    end

    context "with an original file by use" do
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :with_files) }

      it "finds the original_file" do
        expect(service.primary_file)
          .to have_attributes(file_set_id: file_set.id,
                              pcdm_use: include("http://pcdm.org/use#OriginalFile"))
      end
    end

    context "when the FileSet has an #original_file_id" do
      it "always resolves by original_file_id"
    end

    context "when there is no OriginalFile, but files exist" do
      it "resolves the first file"
    end
  end
end
