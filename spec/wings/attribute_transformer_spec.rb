# frozen_string_literal: true
require 'wings/attribute_transformer'

RSpec.describe Wings::AttributeTransformer do
  let(:pcdm_object) { work }
  let(:id)          { 'moomin123' }
  let(:work)        { GenericWork.new(id: id, **attributes) }
  let(:keys)        { attributes.keys }

  let(:attributes) do
    {
      title: ['fake title', 'fake title 2'],
      contributor: ['user1'],
      description: ['a description']
    }
  end

  let(:uris) do
    [RDF::URI('http://example.com/fake1'),
     RDF::URI('http://example.com/fake2')]
  end

  subject { described_class.run(pcdm_object, keys) }

  it "transform the attributes" do
    expect(subject).to include title: work.title,
                               contributor: work.contributor,
                               description: work.description
  end
end
