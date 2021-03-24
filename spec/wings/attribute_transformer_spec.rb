# frozen_string_literal: true
require 'wings/attribute_transformer'

RSpec.describe Wings::AttributeTransformer do
  let(:id)   { 'moomin123' }
  let(:work) { GenericWork.new(id: id, **attributes) }

  let(:attributes) do
    {
      title: ['fake title', 'fake title 2'],
      contributor: ['user1'],
      description: ['a description']
    }
  end

  it "transform the attributes" do
    expect(described_class.run(work))
      .to include title: work.title,
                  contributor: work.contributor.first,
                  description: work.description.first
  end
end
