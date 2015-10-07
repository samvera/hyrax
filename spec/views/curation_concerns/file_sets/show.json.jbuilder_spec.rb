require 'spec_helper'

describe 'curation_concerns/file_sets/show.json.jbuilder' do
  let(:file_set) { create(:file_set) }

  before do
    assign(:file_set, file_set)
    render
  end

  it "renders json of the curation_concern" do
    json = JSON.parse(rendered)
    expect(json['id']).to eq file_set.id
    expect(json['title']).to eq file_set.title
    expected_fields = file_set.class.fields.select { |f| ![:has_model, :create_date].include? f }
    expected_fields << :date_created
    expected_fields.each do |field_symbol|
      expect(json).to have_key(field_symbol.to_s)
    end
  end
end
