require 'spec_helper'

describe 'curation_concerns/generic_files/show.json.jbuilder' do
  let(:generic_file) { FactoryGirl.create(:generic_file) }

  before do
    assign(:generic_file, generic_file)
    render
  end

  it "renders json of the curation_concern" do
    json = JSON.parse(rendered)
    expect(json['id']).to eq generic_file.id
    expect(json['title']).to eq generic_file.title
    expected_fields = generic_file.class.fields.select { |f| ![:has_model, :create_date].include? f }
    expected_fields << :date_created
    expected_fields.each do |field_symbol|
      expect(json).to have_key(field_symbol.to_s)
    end
  end
end
