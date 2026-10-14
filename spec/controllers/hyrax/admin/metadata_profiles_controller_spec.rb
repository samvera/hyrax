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
        schema = Hyrax::FlexibleSchema.new
        allow(schema).to receive(:persisted?).and_return(true)
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
        schema = Hyrax::FlexibleSchema.new
        schema.warnings.add(:profile, 'Warning: sort property foo is not indexed')
        schema.warnings.add(:profile, 'Warning: bar, baz are unused')
        allow(schema).to receive(:persisted?).and_return(true)
        allow(Hyrax::FlexibleSchema).to receive(:create).and_return(schema)
      end

      it 'redirects with a notice and one alert entry per warning' do
        post :import, params: { file: uploaded_file }
        expect(response).to redirect_to(admin_metadata_profiles_path)
        expect(flash[:notice]).to eq('Flexible Metadata Profile was successfully created.')
        expect(flash[:alert]).to eq(['Warning: sort property foo is not indexed', 'Warning: bar, baz are unused'])
      end
    end

    context 'when the profile is invalid' do
      before do
        schema = Hyrax::FlexibleSchema.new
        schema.errors.add(:profile, 'is invalid')
        schema.errors.add(:profile, 'name, label conflict')
        allow(Hyrax::FlexibleSchema).to receive(:create).and_return(schema)
      end

      it 'redirects with one error entry per error' do
        post :import, params: { file: uploaded_file }
        expect(response).to redirect_to(admin_metadata_profiles_path)
        expect(flash[:error]).to eq(['is invalid', 'name, label conflict'])
      end
    end

    context 'when the profile is invalid and has warnings' do
      before do
        schema = Hyrax::FlexibleSchema.new
        schema.errors.add(:profile, 'is invalid')
        schema.warnings.add(:profile, 'Warning: sort property foo is not indexed')
        allow(Hyrax::FlexibleSchema).to receive(:create).and_return(schema)
      end

      it 'redirects with both the errors and the warnings' do
        post :import, params: { file: uploaded_file }
        expect(response).to redirect_to(admin_metadata_profiles_path)
        expect(flash[:error]).to eq(['is invalid'])
        expect(flash[:alert]).to eq(['Warning: sort property foo is not indexed'])
      end
    end
  end
end
