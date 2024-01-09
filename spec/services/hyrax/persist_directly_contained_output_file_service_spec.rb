# frozen_string_literal: true
RSpec.describe Hyrax::PersistDirectlyContainedOutputFileService, :active_fedora do
  # PersistDirectlyContainedOutputFileService is used by FullTextExtract.output_file_service
  let(:file_set) { create(:file_set, user: user) }
  let(:user) { build(:user) }
  let(:content) { "fake file content" }
  let(:resource) { file_set.reload.extracted_text }

  subject(:call) do
    described_class.call(content,
                         format: 'txt',
                         url: file_set.uri,
                         container: 'extracted_text')
  end

  it "persists the file to the specified destination on the given object" do
    expect(call).to be true
    expect(resource.content).to eq("fake file content")
    expect(resource.content.encoding).to eq(Encoding::UTF_8)
  end
end
