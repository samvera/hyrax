# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings/attribute_transformer'

RSpec.describe Wings::AttributeTransformer, :active_fedora do
  let(:id) { 'moomin123' }
  let(:based_near) { Hyrax::ControlledVocabularies::Location.new("https://sws.geonames.org/4920808/") }
  let(:work) { GenericWork.new(id: id, **attributes) }

  let(:attributes) do
    {
      title: ['fake title', 'fake title 2'],
      contributor: ['user1'],
      description: ['a description'],
      based_near: [based_near]
    }
  end

  it "transforms the attributes" do
    converted_work = described_class.run(work)
    expect(converted_work)
      .to include title: work.title,
                  contributor: work.contributor.first,
                  description: work.description.first
    # ensure that based_near is converted from RDF::URI to URI string during valkyrization
    converted_based_near = Array.wrap(converted_work[:based_near]).first
    expect(converted_based_near).to be_a(String)
    expect(converted_based_near).to eq(work.based_near.first.id)
  end
end
