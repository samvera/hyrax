require 'spec_helper'

describe GenericFileRdfDatastream do
  subject { GenericFileRdfDatastream.new(double('base object', uri: '/test/foo', new_record?: true), 'descMetadata') }

  it "should have bibliographicCitation" do
    subject.bibliographic_citation = "foo"
    expect(subject.bibliographic_citation).to eq ["foo"]
  end

  it "should have source" do
    subject.source = "foo"
    expect(subject.source).to eq ["foo"]
  end
end
