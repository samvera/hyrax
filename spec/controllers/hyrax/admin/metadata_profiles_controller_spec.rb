# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Admin::MetadataProfilesController, type: :controller do
  routes { Hyrax::Engine.routes }

  let(:admin) { FactoryBot.create(:admin) }
  let(:profile_file_path) { File.join(fixture_path, 'files', 'm3_profile.yaml') }
  let(:uploaded_file) { fixture_file_upload(profile_file_path, 'application/yaml') }

  before { sign_in admin }

  describe '#import' do
    context 'when no file is provided' do
      it 'redirects with an alert' do
        post :import, params: { file: nil }
        expect(response).to redirect_to(admin_metadata_profiles_path)
        expect(flash[:alert]).to eq('Please select a file to upload')
      end
    end

    context 'when the profile is valid with no warnings' do
      before do
        schema = instance_double(Hyrax::FlexibleSchema, persisted?: true, warnings: double(any?: false, full_messages: []))
        allow(Hyrax::FlexibleSchema).to receive(:create).and_return(schema)
      end

      it 'redirects with a notice' do
        post :import, params: { file: uploaded_file }
        expect(response).to redirect_to(admin_metadata_profiles_path)
        expect(flash[:notice]).to eq('Flexible Metadata Profile was successfully created.')
        expect(flash[:alert]).to be_blank
      end
    end

    context 'when the profile is valid but has warnings' do
      before do
        warning_messages = double(any?: true, full_messages: ['Warning: Profile profile sort property foo is not indexed'])
        schema = instance_double(Hyrax::FlexibleSchema, persisted?: true, warnings: warning_messages)
        allow(Hyrax::FlexibleSchema).to receive(:create).and_return(schema)
      end

      it 'redirects with both a notice and an alert' do
        post :import, params: { file: uploaded_file }
        expect(response).to redirect_to(admin_metadata_profiles_path)
        expect(flash[:notice]).to eq('Flexible Metadata Profile was successfully created.')
        expect(flash[:alert]).to include('sort property foo is not indexed')
      end
    end

    context 'when the profile is invalid' do
      before do
        schema = instance_double(Hyrax::FlexibleSchema, persisted?: false, errors: double(messages: { profile: ['is invalid'] }))
        allow(Hyrax::FlexibleSchema).to receive(:create).and_return(schema)
      end

      it 'redirects with an error' do
        post :import, params: { file: uploaded_file }
        expect(response).to redirect_to(admin_metadata_profiles_path)
        expect(flash[:error]).to include('is invalid')
      end
    end
  end
end
