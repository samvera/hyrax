require 'spec_helper'

describe CurationConcerns::PersistDirectlyContainedOutputFileService do
  let(:object)            { FileSet.create! { |fs| fs.apply_depositor_metadata('justin') } }
  let(:file_path)         { File.join(fixture_path, 'test.tif') }
  let(:file)              { File.new(file_path) }
  let(:destination_name)  { 'the_derivative_name' }
  let(:stream) { StringIO.new("fake file content") }

  it "persists the file to the specified destination on the given object" do
    described_class.call(stream, format: 'txt', url: object.uri, container: 'extracted_text')
    expect(object.reload.extracted_text.content).to eq("fake file content")
  end
end
