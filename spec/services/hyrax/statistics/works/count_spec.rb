RSpec.describe Hyrax::Statistics::Works::Count do
  describe ".by_permission", :clean_repo do
    let(:user1) { build(:user, id: 1) }
    let(:yesterday) { 1.day.ago }

    before do
      create_for_repository(:work, :public, user: user1)
      create_for_repository(:work, :public, user: user1)
      create_for_repository(:work, :public, user: user1).tap do |work|
        work.created_at = 2.days.ago
        persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
        persister.save(resource: work)
      end
      create_for_repository(:registered_generic_work, user: user1)
      create_for_repository(:work, user: user1)
      create_for_repository(:collection, user: user1)
    end

    # Consolidated these tests as they are rather slow when run in sequence
    it "retrieves by no date given, a start date given, and an end date given" do
      no_date_range_given = described_class.by_permission(start_date: nil, end_date: nil)
      expect(no_date_range_given).to include(public: 3, private: 1, registered: 1, total: 5)

      start_date = yesterday.beginning_of_day
      start_date_given = described_class.by_permission(start_date: start_date, end_date: nil)
      expect(start_date_given).to include(public: 2, private: 1, registered: 1, total: 4)

      start_date = 2.days.ago.beginning_of_day
      end_date = yesterday.end_of_day
      start_date_and_end_date_given = described_class.by_permission(start_date: start_date, end_date: end_date)
      expect(start_date_and_end_date_given).to include(public: 1, private: 0, registered: 0, total: 1)
    end
  end
end
