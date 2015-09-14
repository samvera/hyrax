require 'spec_helper'

describe 'curation_concerns/base/show.json.jbuilder' do
  let(:curation_concern) { FactoryGirl.create(:generic_work) }

  before do
    assign(:curation_concern, curation_concern)
    render
  end

  it "renders json of the curation_concern" do
    json = JSON.parse(rendered)
    expect(json['id']).to eq curation_concern.id
    expect(json['title']).to eq curation_concern.title
    expected_fields = curation_concern.class.fields.select { |f| ![:has_model, :create_date].include? f }
    expected_fields << :date_created
    expected_fields.each do |field_symbol|
      expect(json).to have_key(field_symbol.to_s)
    end
  end
end
