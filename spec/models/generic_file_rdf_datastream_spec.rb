require 'spec_helper'

describe GenericFileRdfDatastream, :type => :model do
  it "should have bibliographicCitation" do
    subject.bibliographic_citation = "foo"
    expect(subject.bibliographic_citation).to eq ["foo"]
  end
  it "should have source" do
    subject.source = "foo"
    expect(subject.source).to eq ["foo"]
  end
end
