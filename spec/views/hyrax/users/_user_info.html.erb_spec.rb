# frozen_string_literal: true
RSpec.describe 'hyrax/users/_user_info.html.erb', type: :view do
  let(:user) { stub_model(User, user_key: 'jdoe42', orcid: '000-000', zotero_userid: 'jdoe42zotero') }
  let(:arkivo_api) { true }

  before do
    allow(Hyrax.config).to receive(:arkivo_api?).and_return(arkivo_api)
    render "hyrax/users/user_info", user: user
  end

  it 'displays the orcid' do
    expect(rendered).to have_link '000-000'
  end

  it 'displays a Zotero profile link' do
    expect(rendered).to match(/Zotero Profile/)
  end

  context 'with Zotero disabled' do
    let(:arkivo_api) { false }

    it 'does not display a Zotero profile link' do
      expect(rendered).not_to match(/Zotero Profile/)
    end
  end
end
