describe Sufia::UserStatImporter do
  before do
    allow(Sufia.config).to receive(:analytic_start_date) { dates[0] }

    allow(FileViewStat).to receive(:ga_statistics) do |_date, file_id|
      case file_id
      when bilbo_file_1.id
        bilbo_file_1_pageview_stats
      when bilbo_file_2.id
        bilbo_file_2_pageview_stats
      else
        frodo_file_1_pageview_stats
      end
    end

    allow(FileDownloadStat).to receive(:ga_statistics) do |_date, file_id|
      case file_id
      when bilbo_file_1.id
        bilbo_file_1_download_stats
      when bilbo_file_2.id
        bilbo_file_2_download_stats
      else
        frodo_file_1_download_stats
      end
    end

    allow(WorkViewStat).to receive(:ga_statistics) do |_date, work_id|
      case work_id
      when bilbo_work_1.id
        bilbo_work_1_pageview_stats
      when bilbo_work_2.id
        bilbo_work_2_pageview_stats
      else
        frodo_work_1_pageview_stats
      end
    end
  end

  let(:bilbo) { FactoryGirl.create(:user, email: 'bilbo@example.com') }
  let(:frodo) { FactoryGirl.create(:user, email: 'frodo@example.com') }
  let!(:gollum) { FactoryGirl.create(:user, email: 'gollum@example.com') }

  let!(:bilbo_file_1) do
    FileSet.new(id: 'xyzbilbo1', title: ['bilbo 1']).tap do |f|
      f.apply_depositor_metadata(bilbo.email)
      f.save
    end
  end

  let!(:bilbo_file_2) do
    FileSet.new(id: 'xyzbilbo2', title: ['bilbo 2']).tap do |f|
      f.apply_depositor_metadata(bilbo.email)
      f.save
    end
  end

  let!(:frodo_file_1) do
    FileSet.new(id: 'xyzfrodo1', title: ['frodo 1']).tap do |f|
      f.apply_depositor_metadata(frodo.email)
      f.save
    end
  end

  # work
  let!(:bilbo_work_1) do
    GenericWork.create(id: 'xyzbilbowork1', title: ['bilbo work 1']) do |work|
      work.apply_depositor_metadata(bilbo.email)
    end
  end

  let!(:bilbo_work_2) do
    GenericWork.create(id: 'xyzbilbowork2', title: ['bilbo work 2']) do |work|
      work.apply_depositor_metadata(bilbo.email)
    end
  end

  let!(:frodo_work_1) do
    GenericWork.create(id: 'xyzfrodowork1', title: ['frodo work 1']) do |work|
      work.apply_depositor_metadata(frodo.email)
    end
  end

  let(:dates) {
    ldates = []
    4.downto(0) { |idx| ldates << (Time.zone.today - idx.day) }
    ldates
  }

  let(:date_strs) {
    ldate_strs = []
    dates.each { |date| ldate_strs << date.strftime("%Y%m%d") }
    ldate_strs
  }

  # This is what the data looks like that's returned from Google Analytics via the Legato gem.
  let(:bilbo_file_1_pageview_stats) {
    [
      OpenStruct.new(date: date_strs[0], pageviews: 1),
      OpenStruct.new(date: date_strs[1], pageviews: 2),
      OpenStruct.new(date: date_strs[2], pageviews: 3),
      OpenStruct.new(date: date_strs[3], pageviews: 4),
      OpenStruct.new(date: date_strs[4], pageviews: 5)
    ]
  }

  let(:bilbo_file_2_pageview_stats) {
    [
      OpenStruct.new(date: date_strs[0], pageviews: 11),
      OpenStruct.new(date: date_strs[1], pageviews: 12),
      OpenStruct.new(date: date_strs[2], pageviews: 13),
      OpenStruct.new(date: date_strs[3], pageviews: 14),
      OpenStruct.new(date: date_strs[4], pageviews: 15)
    ]
  }

  let(:frodo_file_1_pageview_stats) {
    [
      OpenStruct.new(date: date_strs[0], pageviews: 2),
      OpenStruct.new(date: date_strs[1], pageviews: 4),
      OpenStruct.new(date: date_strs[2], pageviews: 1),
      OpenStruct.new(date: date_strs[3], pageviews: 1),
      OpenStruct.new(date: date_strs[4], pageviews: 9)
    ]
  }

  # work
  let(:bilbo_work_1_pageview_stats) {
    [
      OpenStruct.new(date: date_strs[0], pageviews: 1),
      OpenStruct.new(date: date_strs[1], pageviews: 2),
      OpenStruct.new(date: date_strs[2], pageviews: 3),
      OpenStruct.new(date: date_strs[3], pageviews: 4),
      OpenStruct.new(date: date_strs[4], pageviews: 5)
    ]
  }

  let(:bilbo_work_2_pageview_stats) {
    [
      OpenStruct.new(date: date_strs[0], pageviews: 11),
      OpenStruct.new(date: date_strs[1], pageviews: 12),
      OpenStruct.new(date: date_strs[2], pageviews: 13),
      OpenStruct.new(date: date_strs[3], pageviews: 14),
      OpenStruct.new(date: date_strs[4], pageviews: 15)
    ]
  }

  let(:frodo_work_1_pageview_stats) {
    [
      OpenStruct.new(date: date_strs[0], pageviews: 2),
      OpenStruct.new(date: date_strs[1], pageviews: 4),
      OpenStruct.new(date: date_strs[2], pageviews: 1),
      OpenStruct.new(date: date_strs[3], pageviews: 1),
      OpenStruct.new(date: date_strs[4], pageviews: 9)
    ]
  }

  let(:bilbo_file_1_download_stats) {
    [
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo1", date: date_strs[0], totalEvents: "2"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo1", date: date_strs[1], totalEvents: "3"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo1", date: date_strs[2], totalEvents: "5"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo1", date: date_strs[3], totalEvents: "3"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo1", date: date_strs[4], totalEvents: "7")
    ]
  }

  let(:bilbo_file_2_download_stats) {
    [
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo2", date: date_strs[0], totalEvents: "1"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo2", date: date_strs[1], totalEvents: "4"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo2", date: date_strs[2], totalEvents: "3"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo2", date: date_strs[3], totalEvents: "2"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "bilbo2", date: date_strs[4], totalEvents: "3")
    ]
  }

  let(:frodo_file_1_download_stats) {
    [
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "frodo1", date: date_strs[0], totalEvents: "5"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "frodo1", date: date_strs[1], totalEvents: "4"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "frodo1", date: date_strs[2], totalEvents: "2"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "frodo1", date: date_strs[3], totalEvents: "1"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "frodo1", date: date_strs[4], totalEvents: "6")
    ]
  }

  describe 'with empty cache' do
    it 'for each user it adds one entry per day to the cache' do
      described_class.new.import

      bilbos_stats = UserStat.where(user_id: bilbo.id).order(date: :asc)
      expect(bilbos_stats.count).to eq 4

      bilbos_stats.each_with_index do |actual_values, i|
        expected_file_views = bilbo_file_1_pageview_stats[i].pageviews + bilbo_file_2_pageview_stats[i].pageviews
        expected_work_views = bilbo_work_1_pageview_stats[i].pageviews + bilbo_work_2_pageview_stats[i].pageviews
        expected_file_downloads = bilbo_file_1_download_stats[i].totalEvents.to_i + bilbo_file_2_download_stats[i].totalEvents.to_i
        expected_values = { date: dates[i], views: expected_file_views, work_views: expected_work_views, downloads: expected_file_downloads }
        assert_stats_match(expected_values, actual_values)
      end

      frodos_stats = UserStat.where(user_id: frodo.id).order(date: :asc)
      expect(frodos_stats.count).to eq 4

      frodos_stats.each_with_index do |actual_values, i|
        expected_file_views = frodo_file_1_pageview_stats[i].pageviews
        expected_work_views = frodo_work_1_pageview_stats[i].pageviews
        expected_file_downloads = frodo_file_1_download_stats[i].totalEvents.to_i
        expected_values = { date: dates[i], views: expected_file_views, work_views: expected_work_views, downloads: expected_file_downloads }
        assert_stats_match(expected_values, actual_values)
      end

      expect(UserStat.count).to eq bilbos_stats.count + frodos_stats.count
    end

    context "when Google analytics throws an error" do
      let(:importer) { described_class.new(number_of_retries: 4) }

      context "both error out completely" do
        before do
          expect(FileDownloadStat).to receive(:ga_statistics).exactly(12).times.and_raise(StandardError.new("GA error"))
          expect(WorkViewStat).to receive(:ga_statistics).exactly(12).times.and_raise(StandardError.new("GA error"))
          expect(FileViewStat).to receive(:ga_statistics).exactly(12).times.and_raise(StandardError.new("GA error"))
        end

        it "stops after 4 tries on each of the 3 files" do
          importer.import
          expect(UserStat.count).to eq 0
        end
      end

      context "Only View stats error out completely" do
        before do
          expect(FileViewStat).to receive(:ga_statistics).exactly(12).times.and_raise(StandardError.new("GA error"))
        end
        it "gathers the download stats even though the view stats are failing" do
          importer.import
          expect(UserStat.count).to eq 8 # 2 users for 4 days
          UserStat.all.each do |stat|
            expect(stat.file_views).to eq 0
            expect(stat.work_views).not_to eq 0
            expect(stat.file_downloads).not_to eq 0
          end
        end
      end

      context "Only Download stats error out completely" do
        before do
          expect(FileDownloadStat).to receive(:ga_statistics).exactly(12).times.and_raise(StandardError.new("GA error"))
        end
        it "gathers the view stats even though the download stats are failing" do
          importer.import
          expect(UserStat.count).to eq 8 # 2 users for 4 days
          UserStat.all.each do |stat|
            expect(stat.file_views).not_to eq 0
            expect(stat.work_views).not_to eq 0
            expect(stat.file_downloads).to eq 0
          end
        end
      end
    end
  end

  describe 'with existing data in cache' do
    before do
      [dates[0], dates[1]].each_with_index do |date, i|
        UserStat.create!(user_id: bilbo.id, date: date, file_views: 100 + i, file_downloads: 200 + i, work_views: 300)
      end
      UserStat.create!(user_id: frodo.id, date: dates[0], file_views: 300, file_downloads: 400, work_views: 500)
    end

    it "doesn't duplicate entries for existing dates" do
      expect(User.count).to eq 3
      expect(UserStat.count).to eq 3

      described_class.new.import

      bilbos_stats = UserStat.where(user_id: bilbo.id).order(date: :asc)
      expect(bilbos_stats.count).to eq 4

      expect(bilbos_stats[0].file_views).to eq(bilbo_file_1_pageview_stats[0].pageviews + bilbo_file_2_pageview_stats[0].pageviews)
      expect(bilbos_stats[0].file_downloads).to eq(bilbo_file_1_download_stats[0].totalEvents.to_i + bilbo_file_2_download_stats[0].totalEvents.to_i)

      expect(bilbos_stats[1].file_views).to eq(bilbo_file_1_pageview_stats[1].pageviews + bilbo_file_2_pageview_stats[1].pageviews)
      expect(bilbos_stats[1].file_downloads).to eq(bilbo_file_1_download_stats[1].totalEvents.to_i + bilbo_file_2_download_stats[1].totalEvents.to_i)

      frodos_stats = UserStat.where(user_id: frodo.id).order(date: :asc)
      expect(frodos_stats.count).to eq 4

      expect(frodos_stats[0].file_views).to eq(frodo_file_1_pageview_stats[0].pageviews)

      expect(frodos_stats[0].file_downloads).to eq(frodo_file_1_download_stats[0].totalEvents.to_i)
    end

    it "processes the oldest records first" do
      # Since Gollum has no stats it will be the first one processed.
      # Followed by Frodo and Bilbo.
      sorted_ids = described_class.new.sorted_users.map(&:id)
      expect(sorted_ids).to eq([gollum.id, frodo.id, bilbo.id])
    end

    context "a user is already up to date" do
      let(:importer) { described_class.new }
      before do
        allow(importer).to receive(:sorted_users).and_return([gollum, frodo, bilbo])
        UserStat.create!(user_id: bilbo.id, date: dates[3], file_views: 999, file_downloads: 555)
      end

      it "skips if we already have uptodate information" do
        expect(importer).to receive(:file_ids_for_user).with(gollum).and_call_original
        expect(importer).to receive(:file_ids_for_user).with(frodo).and_call_original
        expect(importer).not_to receive(:file_ids_for_user).with(bilbo)
        importer.import
      end
    end
  end
end

def assert_stats_match(expected_value, actual_value)
  expect(actual_value.date).to eq expected_value[:date]
  expect(actual_value.file_views).to eq expected_value[:views]
  expect(actual_value.work_views).to eq expected_value[:work_views]
  expect(actual_value.file_downloads).to eq expected_value[:downloads]
end
