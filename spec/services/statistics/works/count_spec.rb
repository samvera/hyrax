RSpec.describe Sufia::Statistics::Works::Count do
  let(:user1) { create(:user) }
  let(:service) { described_class.new(start_date, end_date) }
  let(:start_date) { nil }
  let(:end_date) { nil }

  describe "#by_permission" do
    subject { service.by_permission }

    before do
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

    it "retrieves all documents by permissions" do
      expect(subject).to include(public: 3, private: 1, registered: 1, total: 5)
    end

    context "when passing a start date" do
      let(:yesterday) { 1.day.ago }
      let(:start_date) { yesterday.beginning_of_day }
      it "gets documents after date by permissions" do
        expect(subject).to include(public: 2, private: 1, registered: 1, total: 4)
      end

      context "when passing an end date" do
        let(:start_date) { 2.days.ago.beginning_of_day }
        let(:end_date) { yesterday.end_of_day }
        it "get documents between dates by permissions" do
          expect(subject).to include(public: 1, private: 0, registered: 0, total: 1)
        end
      end
    end
  end
end
