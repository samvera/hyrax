# frozen_string_literal: true
RSpec.describe 'Paging the metadata profile list', type: :request do
  let(:admin) { FactoryBot.create(:admin) }
  let(:profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }

  before do
    2.times { Hyrax::FlexibleSchema.new(profile: profile).save!(validate: false) }
    login_as admin
    allow(Hyrax::FlexibleSchema).to receive(:default_per_page).and_return(1)
  end

  it 'shows the profiles on the requested page' do
    first_page_schema, second_page_schema = Hyrax::FlexibleSchema.order(updated_at: :desc).first(2)

    get hyrax.admin_metadata_profiles_path(metadata_profile_entries_page: 2)

    expect(response.body).to include("<td>#{second_page_schema.id.to_f}</td>")
    expect(response.body).not_to include("<td>#{first_page_schema.id.to_f}</td>")
  end
end
