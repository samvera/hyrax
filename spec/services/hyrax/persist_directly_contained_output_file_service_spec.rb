RSpec.describe Hyrax::PersistDirectlyContainedOutputFileService do
  # PersistDirectlyContainedOutputFileService is used by FullTextExtract.output_file_service
  let(:object) { FileSet.create! { |fs| fs.apply_depositor_metadata('justin') } }
  let(:stream) { "fake file content" }
  subject(:call) do
    described_class.call(stream,
                         format: 'txt',
                         url: object.uri,
                         container: 'extracted_text')
  end

  it "persists the file to the specified destination on the given object" do
    expect(call).to be true
    expect(object.reload.extracted_text.content).to eq("fake file content")
  end
end
