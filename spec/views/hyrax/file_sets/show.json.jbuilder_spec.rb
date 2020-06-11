# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/show.json.jbuilder' do
  let(:presenter) do
    instance_double(Hyrax::FileSetPresenter,
                    id: '123',
                    title: ['title'],
                    label: '',
                    creator: ['Janet'],
                    depositor: '',
                    date_uploaded: '',
                    date_modified: '')
  end

  before do
    assign(:presenter, presenter)
    render
  end

  it "renders json of the curation_concern" do
    json = JSON.parse(rendered)
    expect(json['id']).to eq presenter.id
    expect(json['title']).to match_array presenter.title
    expected_fields = [:title, :label, :creator, :depositor, :date_uploaded, :date_modified]
    expected_fields.each do |field_symbol|
      expect(json).to have_key(field_symbol.to_s)
    end
  end
end
