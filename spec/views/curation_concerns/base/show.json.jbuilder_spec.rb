require 'spec_helper'

describe 'curation_concerns/base/show.json.jbuilder' do
  let(:curation_concern) { create(:generic_work) }

  before do
    allow(curation_concern).to receive(:etag).and_return('W/"87f79d2244ded4239ad1f0e822c8429b1e72b66c"')
    assign(:curation_concern, curation_concern)
    render
  end

  it "renders json of the curation_concern" do
    json = JSON.parse(rendered)
    expect(json['id']).to eq curation_concern.id
    expect(json['title']).to match_array curation_concern.title
    expected_fields = curation_concern.class.fields.select { |f| ![:has_model, :create_date].include? f }
    expected_fields << :date_created
    expected_fields.each do |field_symbol|
      expect(json).to have_key(field_symbol.to_s)
    end
    expect(json['version']).to eq 'W/"87f79d2244ded4239ad1f0e822c8429b1e72b66c"'
  end
end
