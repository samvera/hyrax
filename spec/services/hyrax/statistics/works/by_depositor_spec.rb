RSpec.describe Hyrax::Statistics::Works::ByDepositor do
  let(:service) { described_class.new }

  describe "#query" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    before do
      gf = build(:generic_work, user: user1, id: '1234567')
      gf.update_index
      gf = build(:generic_work, user: user2, id: '2345678')
      gf.update_index
      gf = build(:generic_work, user: user1, id: '3456789')
      gf.update_index
      gf = build(:generic_work, user: user1, id: '4567890')
      gf.update_index
    end

    subject { service.query }

    it "is a list of categories" do
      expect(subject).to eq [{ label: user1.user_key, data: 3 },
                             { label: user2.user_key, data: 1 }]
    end
  end
end
