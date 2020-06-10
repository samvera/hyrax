# frozen_string_literal: true
RSpec.describe 'Legacy GenericFile routes', type: :request do
  it 'redirects to the work' do
    get '/files/gm80hv36p'
    expect(response).to redirect_to("/concern/generic_works/gm80hv36p")
    expect(response.code).to eq '301' # Moved Permanently
  end
end
