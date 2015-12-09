require 'spec_helper'

describe Admin::StatsController, type: :controller do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

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
      expect(response.body).to include('Statistics for Blacklight')
      expect(response.body).to include('Total Blacklight Users')
    end

    describe "querying stats_filters" do
      let(:one_day_ago_date) { 1.day.ago.to_datetime }
      let(:two_days_ago_date) { 2.days.ago.to_datetime.end_of_day }
      let(:one_day_ago) { one_day_ago_date.strftime("%Y-%m-%d") }
      let(:two_days_ago) { two_days_ago_date.strftime("%Y-%m-%d") }

      it "defaults to latest 5 users" do
        get :index
        expect(assigns[:presenter].recent_users).to eq(User.order('created_at DESC').limit(5))
      end

      it "allows queries against stats_filters without an end date" do
        expect(User).to receive(:where).with('id' => user1.id).once.and_return([user1])
        expect(User).to receive(:recent_users).with(one_day_ago_date, nil).and_return([user2])
        get :index, stats_filters: { start_date: one_day_ago }
        expect(assigns[:presenter].recent_users).to eq([user2])
      end

      it "allows queries against stats_filters with an end date" do
        expect(User).to receive(:recent_users).with(two_days_ago_date, one_day_ago_date).and_return([user2])
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
          Collection.create(title: "test") do |c|
            c.apply_depositor_metadata(user1.user_key)
          end
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
          expect(GenericWork).to receive(:find_by_date_created).exactly(3).times.with(1.day.ago.to_datetime, nil).and_call_original
          expect(GenericWork).to receive(:where_public).and_call_original
          expect(GenericWork).to receive(:where_registered).and_call_original
          get :index, stats_filters: { start_date: 1.day.ago.strftime("%Y-%m-%d") }
        end
      end

      context "when date range set" do
        it "queries by start and date" do
          expect(GenericWork).to receive(:find_by_date_created).exactly(3).times.with(1.day.ago.to_datetime, 0.days.ago.to_datetime.end_of_day).and_call_original
          expect(GenericWork).to receive(:where_public).and_call_original
          expect(GenericWork).to receive(:where_registered).and_call_original
          get :index, stats_filters: { start_date: 1.day.ago.strftime("%Y-%m-%d"), end_date: 0.days.ago.strftime("%Y-%m-%d") }
        end
      end
    end

    describe "depositor counts" do
      before do
        GenericWork.new(id: "abc123") do |gf|
          gf.apply_depositor_metadata(user1)
          gf.update_index
        end
        GenericWork.new(id: "def123") do |gf|
          gf.apply_depositor_metadata(user2)
          gf.update_index
        end
        GenericWork.new(id: "zzz123") do |gf|
          gf.create_date = [2.days.ago]
          gf.apply_depositor_metadata(user1)
          gf.update_index
        end
        Collection.new(id: "ccc123") do |c|
          c.apply_depositor_metadata(user1)
          c.update_index
        end
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
          (1..12).each do |number|
            luser = User.create(email: "user#{number}@blah.com", password: "blahbalh")
            users << luser
            GenericWork.new(id: "more#{number}") do |gf|
              gf.apply_depositor_metadata(luser)
              gf.update_index
            end
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
      before do
        FileSet.new(id: "abc123") do |gf|
          gf.apply_depositor_metadata(user1)
          gf.mime_type = 'image/png'
          gf.update_index
        end
        FileSet.new(id: "def123") do |gf|
          gf.apply_depositor_metadata(user2)
          gf.mime_type = 'image/png'
          gf.update_index
        end
        FileSet.new(id: "zzz123") do |gf|
          gf.create_date = [2.days.ago]
          gf.apply_depositor_metadata(user1)
          gf.mime_type = 'image/jpeg'
          gf.update_index
        end
      end

      it "gathers formats" do
        get :index
        expect(assigns[:presenter].top_formats).to eq("png" => 2, "jpeg" => 1)
      end
    end
  end
end
