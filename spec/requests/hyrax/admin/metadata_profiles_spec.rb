# frozen_string_literal: true
RSpec.describe 'Importing a metadata profile', type: :request do
  let(:admin) { FactoryBot.create(:admin) }
  let(:uploaded_file) { fixture_file_upload(File.join(fixture_path, 'files', 'm3_profile.yaml'), 'application/yaml') }
  let(:schema) { Hyrax::FlexibleSchema.new }
  let(:messages) { Array.new(60) { |i| "Property 'property_#{i}' has a problem that takes about a hundred characters to describe." } }

  before do
    login_as admin
    allow(Hyrax::FlexibleSchema).to receive(:create).and_return(schema)
  end

  context 'when a failed import has more messages than the session cookie can hold' do
    before do
      messages.each { |message| schema.errors.add(:profile, message) }
      messages.each { |message| schema.warnings.add(:profile, "Warning: #{message}") }
    end

    it 'shows every error and warning' do
      post hyrax.import_admin_metadata_profiles_path, params: { file: uploaded_file }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(messages.first, messages.last, "Warning: #{messages.last}")
    end
  end

  context 'when a successful import has more warnings than the session cookie can hold' do
    before do
      messages.each { |message| schema.warnings.add(:profile, "Warning: #{message}") }
      allow(schema).to receive(:persisted?).and_return(true)
    end

    it 'shows the first warnings and a count of the rest' do
      post hyrax.import_admin_metadata_profiles_path, params: { file: uploaded_file }
      follow_redirect!

      expect(response.body).to include("Warning: #{messages.first}")
      expect(response.body).to match(/and \d+ more warnings/)
    end
  end
end
