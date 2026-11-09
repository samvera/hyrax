# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Bulkrax token authentication', type: :request do
  around do |example|
    previous_token = ENV['BULKRAX_API_TOKEN']
    ENV['BULKRAX_API_TOKEN'] = 'test-token'
    example.run
  ensure
    ENV['BULKRAX_API_TOKEN'] = previous_token
  end

  let(:headers) { { 'CONTENT_TYPE' => 'application/json', 'Authorization' => 'Token: test-token' } }

  it 'rejects a JSON importer listing even with the configured token' do
    get '/importers', headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects JSON importer creation even with the configured token' do
    post '/importers', params: '{}', headers: headers
    expect(response).to have_http_status(:unauthorized)
  end

  it 'keeps browser requests on the normal sign-in path' do
    get '/importers'
    expect(response).to redirect_to(new_user_session_path)
  end
end
