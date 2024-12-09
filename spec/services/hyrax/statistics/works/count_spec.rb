# frozen_string_literal: true
RSpec.describe Hyrax::Statistics::Works::Count do
  describe ".by_permission", :clean_repo do
    let(:user1) { build(:user, id: 1) }
    let(:yesterday) { 1.day.ago }
    let(:wings_disabled) { Hyrax.config.disable_wings }

    before do
      if wings_disabled
        valkyrie_create(:monograph, :public, depositor: user1.user_key)
        valkyrie_create(:monograph, :public, depositor: user1.user_key)

        # Valkyrie postgres adapter filters created_at letting ActiveRecord handle it.
        allow(Valkyrie::Persistence::Postgres::ORM::Resource).to receive(:current_time_from_proper_timezone).and_return(2.days.ago)
        valkyrie_create(:monograph, :public, depositor: user1.user_key, created_at: [2.days.ago])
        allow(Valkyrie::Persistence::Postgres::ORM::Resource).to receive(:current_time_from_proper_timezone).and_call_original

        valkyrie_create(:monograph, read_groups: ['registered'], depositor: user1.user_key)
        valkyrie_create(:monograph, read_groups: ['private'], depositor: user1.user_key)
        valkyrie_create(:hyrax_collection, depositor: user1.user_key)
      else
        build(:public_generic_work, user: user1, id: "pdf1223").update_index
        build(:public_generic_work, user: user1, id: "wav1223").update_index
        build(:public_generic_work, user: user1, id: "mp31223", create_date: [2.days.ago]).update_index
        build(:registered_generic_work, user: user1, id: "reg1223").update_index
        build(:generic_work, user: user1, id: "private1223").update_index
        Collection.new(id: "ccc123") do |c|
          c.apply_depositor_metadata(user1)
          c.update_index
        end
      end
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
