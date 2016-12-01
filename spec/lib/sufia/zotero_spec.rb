describe Sufia::Zotero do
  describe '.publications_url' do
    let(:user_id) { 'foobar' }
    it 'returns a string' do
      expect(described_class.publications_url(user_id)).to eq "/users/#{user_id}/publications/items"
    end
  end
end
