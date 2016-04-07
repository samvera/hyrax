require 'spec_helper'

describe Admin::StatsController, type: :controller do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:two_days_ago_date) { Time.zone.now - 2.days }
  let(:one_day_ago_date)  { Time.zone.now - 1.day }

  before do
    allow(user1).to receive(:groups).and_return(['admin'])
    allow(user2).to receive(:groups).and_return(['not-admin'])
  end

  describe "statistics page" do
    render_views
    before do
      sign_in user1
    end
    it "counts the users" do
      get :index
      expect(assigns[:presenter].users_count).to eq 2
    end

    it 'allows an authorized user to view the page' do
      get :index
      expect(response).to be_success
      expect(response.body).to include('Statistics for Sufia')
      expect(response.body).to include('Total Sufia Users')
    end

    describe "querying stats_filters" do
      let(:one_day_ago)  { one_day_ago_date.strftime("%Y-%m-%d") }
      let(:two_days_ago) { two_days_ago_date.strftime("%Y-%m-%d") }

      it "defaults to latest 5 users" do
        get :index
        expect(assigns[:presenter].recent_users).to eq(User.order('created_at DESC').limit(5))
      end

      it "allows queries against stats_filters without an end date" do
        expect(User).to receive(:where).with('id' => user1.id).once.and_return([user1])
        expect(User).to receive(:recent_users).with(one_day_ago_date.beginning_of_day, nil).and_return([user2])
        get :index, stats_filters: { start_date: one_day_ago }
        expect(assigns[:presenter].recent_users).to eq([user2])
      end

      it "allows queries against stats_filters with an end date" do
        expect(User).to receive(:recent_users).with(two_days_ago_date.beginning_of_day, one_day_ago_date.end_of_day).and_return([user2])
        get :index, stats_filters: { start_date: two_days_ago, end_date: one_day_ago }
        expect(assigns[:presenter].recent_users).to eq([user2])
      end
    end

    describe "files_count" do
      let(:original_files_count) do
        work = create(:generic_work, user: user1)
        original_files_count = GenericWork.count
        ActiveFedora::SolrService.instance.conn.delete_by_id(work.id)
        original_files_count
      end
      it "provides accurate files_count, ensuring that solr deletes have been expunged first" do
        get :index
        expect(assigns[:presenter].files_count[:total]).to eq(original_files_count - 1)
      end
    end

    describe "counts" do
      context "when date range not set" do
        before do
          build(:generic_work, user: user1, id: "abc1223").update_index
          build(:public_generic_work, user: user1, id: "bbb1223").update_index
          build(:registered_generic_work, user: user1, id: "ccc1223").update_index
          create(:collection, user: user1)
        end

        it "includes files but not collections" do
          get :index
          expect(assigns[:presenter].files_count[:total]).to eq(3)
          expect(assigns[:presenter].files_count[:public]).to eq(1)
          expect(assigns[:presenter].files_count[:registered]).to eq(1)
          expect(assigns[:presenter].files_count[:private]).to eq(1)
        end
      end

      context "when start date set" do
        it "queries by start date" do
          expect(GenericWork).to receive(:find_by_date_created).exactly(3).times.with(1.day.ago.beginning_of_day, nil).and_call_original
          expect(GenericWork).to receive(:where_public).and_call_original
          expect(GenericWork).to receive(:where_registered).and_call_original
          get :index, stats_filters: { start_date: 1.day.ago.strftime("%Y-%m-%d") }
        end
      end

      context "when date range set" do
        it "queries by start and date" do
          expect(GenericWork).to receive(:find_by_date_created).exactly(3).times.with(1.day.ago.beginning_of_day, 0.days.ago.end_of_day).and_call_original
          expect(GenericWork).to receive(:where_public).and_call_original
          expect(GenericWork).to receive(:where_registered).and_call_original
          get :index, stats_filters: { start_date: 1.day.ago.strftime("%Y-%m-%d"), end_date: 0.days.ago.strftime("%Y-%m-%d") }
        end
      end
    end

    describe "depositor counts" do
      let!(:old_work) { create(:work, user: user1) }

      before do
        create(:work, user: user1)
        create(:work, user: user2)
        create(:collection, user: user1)
        allow(old_work).to receive(:create_date).and_return(two_days_ago_date.to_datetime)
        old_work.update_index
      end

      it "gathers user deposits" do
        get :index
        expect(assigns[:presenter].depositors).to include({ key: user1.user_key, deposits: 2, user: user1 }, key: user2.user_key, deposits: 1, user: user2)
        expect(assigns[:presenter].active_users).to eq("example.com" => 4, user1.user_key.split('@')[0] => 3, user2.user_key.split('@')[0] => 1)
      end

      it "gathers user deposits during a date range" do
        get :index, stats_filters: { start_date: 1.day.ago.strftime("%Y-%m-%d"), end_date: 0.days.ago.strftime("%Y-%m-%d") }
        expect(assigns[:presenter].depositors).to include({ key: user1.user_key, deposits: 1, user: user1 }, key: user2.user_key, deposits: 1, user: user2)
      end

      context "more than 10 users" do
        let(:users) { [] }
        before do
          12.times do
            luser = create(:user)
            users << luser
            create(:work, user: luser)
          end
        end

        it "gathers user deposits" do
          get :index
          expect(assigns[:presenter].depositors).to include({ key: user1.user_key, deposits: 2, user: user1 }, key: user2.user_key, deposits: 1, user: user2)
          users.each { |user| expect(assigns[:presenter].depositors).to include(key: user.user_key, deposits: 1, user: user) }
        end
      end
    end
    describe "top formats" do
      let!(:old_file) { create(:file_set, user: user1, mime_type: 'image/jpeg') }
      before do
        create(:file_set, user: user1, mime_type: 'image/png')
        create(:file_set, user: user2, mime_type: 'image/png')
        allow(old_file).to receive(:create).and_return(two_days_ago_date)
        old_file.update_index
      end

      it "gathers formats" do
        get :index
        expect(assigns[:presenter].top_formats).to eq("png" => 2, "jpeg" => 1)
      end
    end
  end
end
