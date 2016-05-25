describe Sufia::AdminStatsPresenter do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  let(:one_day_ago_date)  { Time.zone.now - 1.day }
  let(:two_days_ago_date) { Time.zone.now - 2.days }
  let(:start_date) { '' }
  let(:end_date) { '' }

  let(:filters) { { start_date: start_date, end_date: end_date } }
  let(:limit) { 5 }
  let(:service) { described_class.new(filters, limit) }

  describe '#active_users' do
    let!(:old_work) { create(:work, user: user1) }
    let!(:work1) { create(:work, user: user1) }
    let!(:work2) { create(:work, user: user2) }
    let!(:collection1) { create(:public_collection, user: user1) }

    before do
      allow(old_work).to receive(:create_date).and_return(two_days_ago_date.to_datetime)
      old_work.update_index
      # Force optimize so the terms component is caught up.
      ActiveFedora::SolrService.instance.conn.optimize
    end

    subject { service.active_users }
    it "returns statistics" do
      expect(subject).to eq(user1.user_key => 3, user2.user_key => 1)
    end
  end

  describe "#top_formats" do
    let!(:file_set1) { create(:file_set, user: user1) }
    let!(:file_set2) { create(:file_set, user: user1) }
    let!(:file_set3) { create(:file_set, user: user2) }

    before do
      allow(file_set1).to receive(:create).and_return(two_days_ago_date)
      allow(file_set1).to receive(:mime_type).and_return('image/png')
      allow(file_set2).to receive(:mime_type).and_return('image/png')
      allow(file_set3).to receive(:mime_type).and_return('image/jpeg')
      file_set1.update_index
      file_set2.update_index
      file_set3.update_index
    end

    subject { service.top_formats }

    it "gathers formats" do
      expect(subject).to eq("png" => 2, "jpeg" => 1)
    end
  end

  describe "#files_count" do
    before do
      build(:generic_work, user: user1, id: "abc1223").update_index
      build(:public_generic_work, user: user1, id: "bbb1223").update_index
      build(:registered_generic_work, user: user1, id: "ccc1223").update_index
      create(:public_collection, user: user1)
    end

    let(:one_day_ago)  { one_day_ago_date.strftime("%Y-%m-%d") }
    let(:two_days_ago) { two_days_ago_date.strftime("%Y-%m-%d") }

    subject { service.files_count }

    it "includes files but not collections" do
      expect(subject[:total]).to eq(3)
      expect(subject[:public]).to eq(1)
      expect(subject[:registered]).to eq(1)
      expect(subject[:private]).to eq(1)
    end

    context "when there is uncommitted work" do
      let(:original_files_count) do
        work = create(:generic_work, user: user1)
        original_files_count = GenericWork.count
        ActiveFedora::SolrService.instance.conn.delete_by_id(work.id)
        original_files_count
      end
      it "provides accurate files_count, ensuring that solr deletes have been expunged first" do
        expect(subject[:total]).to eq(original_files_count - 1)
      end
    end

    context "when start date is provided" do
      let(:start_date) { one_day_ago }
      let(:system_stats) { double(document_by_permission: {}) }
      it "queries by start date" do
        expect(Sufia::SystemStats).to receive(:new).with(5, start_date, end_date).and_return(system_stats)
        subject
      end
    end

    context "when start and end date is provided" do
      let(:start_date) { two_days_ago }
      let(:end_date) { one_day_ago }
      let(:system_stats) { double(document_by_permission: {}) }
      it "queries by start and date" do
        expect(Sufia::SystemStats).to receive(:new).with(5, start_date, end_date).and_return(system_stats)
        subject
      end
    end
  end

  describe "recent_users" do
    let(:one_day_ago)  { one_day_ago_date.strftime("%Y-%m-%d") }
    let(:two_days_ago) { two_days_ago_date.strftime("%Y-%m-%d") }
    subject { service.recent_users }

    context "default range" do
      it "defaults to latest 5 users" do
        expect(subject).to eq(User.order('created_at DESC').limit(5))
      end
    end

    context "with a start and no end date" do
      let(:start_date) { one_day_ago }
      it "allows queries against stats_filters" do
        expect(User).to receive(:recent_users).with(one_day_ago_date.beginning_of_day, nil).and_return([user2])
        expect(subject).to eq [user2]
      end
    end

    context 'with start and end dates' do
      let(:start_date) { two_days_ago }
      let(:end_date) { one_day_ago }

      it "queries" do
        expect(User).to receive(:recent_users).with(two_days_ago_date.beginning_of_day, one_day_ago_date.end_of_day).and_return([user2])
        expect(subject).to eq [user2]
      end
    end
  end

  describe '#users_count' do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }

    subject { service.users_count }
    it { is_expected.to eq 2 }
  end

  describe '#date_filter_string' do
    subject { service.date_filter_string }

    context "default range" do
      it { is_expected.to eq 'unfiltered' }
    end

    context "with a start and no end date" do
      let(:start_date) { '2015-12-14' }
      let(:today) { Time.zone.today.strftime("%Y-%m-%d") }
      it { is_expected.to eq "2015-12-14 to #{today}" }
    end

    context 'with start and end dates' do
      let(:start_date) { '2015-12-14' }
      let(:end_date) { '2016-05-12' }

      it { is_expected.to eq '2015-12-14 to 2016-05-12' }
    end
  end
end
