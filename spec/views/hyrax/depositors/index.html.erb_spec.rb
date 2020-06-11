# frozen_string_literal: true
RSpec.describe "hyrax/depositors/index.html.erb", type: :view do
  before do
    allow(controller).to receive(:current_user).and_return(some_user)
    assign :user, some_user
  end

  let(:some_user) { build(:user) }

  it 'renders proxy partial' do
    render
    expect(rendered).to match(/Authorize Proxies/)
  end
end
