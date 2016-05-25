describe 'users/_user_info.html.erb', type: :view do
  let(:user) { stub_model(User, user_key: 'jdoe42') }

  context 'with Zotero disabled' do
    before do
      allow(Sufia.config).to receive(:arkivo_api) { false }
      allow(user).to receive(:zotero_userid).and_raise(NoMethodError)
      render "users/user_info", user: user
    end

    it 'does not display a Zotero profile link' do
      expect(rendered).not_to match(/Zotero Profile/)
    end
  end

  context 'with Zotero enabled' do
    before do
      allow(Sufia.config).to receive(:arkivo_api) { true }
      allow(user).to receive(:zotero_userid) { 'jdoe42zotero' }
      render "users/user_info", user: user
    end

    it 'displays a Zotero profile link' do
      expect(rendered).to match(/Zotero Profile/)
    end
  end
end
