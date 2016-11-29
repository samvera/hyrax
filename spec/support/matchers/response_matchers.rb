RSpec::Matchers.define :fail_redirect_and_flash do |path, flash_message|
  match do |response|
    expect(response.status).to eq 302
    expect(response).to redirect_to(path)
    expect(flash[:alert]).to eq flash_message
  end
end
