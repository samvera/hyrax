RSpec.describe Hyrax::Statistics::Works::ByDepositor do
  describe ".query", :clean_repo do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      3.times { create_for_repository(:work, user: user1) }
      create_for_repository(:work, user: user2)
    end

    subject { described_class.query }

    it "is a list of categories" do
      expect(subject).to eq [{ label: user1.user_key, data: 3 },
                             { label: user2.user_key, data: 1 }]
    end
  end
end
