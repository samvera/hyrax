require 'spec_helper'

RSpec.describe Hyrax::PersistDirectlyContainedOutputFileService do
  # PersistDirectlyContainedOutputFileService is used by FullTextExtract.output_file_service
  let(:file_set) { FileSet.create! { |fs| fs.apply_depositor_metadata('justin') } }
  let(:content) { "fake file content" }
  subject(:call) do
    described_class.call(content,
                         format: 'txt',
                         url: file_set.uri,
                         container: 'extracted_text')
  end
  let(:resource) { file_set.reload.extracted_text }

  it "persists the file to the specified destination on the given object" do
    expect(call).to be true
    expect(resource.content).to eq("fake file content")
    expect(resource.content.encoding).to eq(Encoding::UTF_8)
  end
end
