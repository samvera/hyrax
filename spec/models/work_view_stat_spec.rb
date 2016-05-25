RSpec.describe WorkViewStat, type: :model do
  let(:work_id) { "199" }
  let(:user_id) { 123 }
  let(:date) { DateTime.new.in_time_zone }
  let(:work_stat) { described_class.create(work_views: "25", date: date, work_id: work_id, user_id: user_id) }

  it "has attributes" do
    expect(work_stat).to respond_to(:work_views)
    expect(work_stat).to respond_to(:date)
    expect(work_stat).to respond_to(:work_id)
    expect(work_stat.work_id).to eq("199")
    expect(work_stat.date).to eq(date)
    expect(work_stat.work_views).to eq(25)
    expect(work_stat.user_id).to eq(user_id)
  end

  describe "#get_float_statistics" do
    let(:dates) {
      ldates = []
      4.downto(0) { |idx| ldates << (Time.zone.today - idx.day) }
      ldates
    }
    let(:date_strs) {
      dates.map { |date| date.strftime("%Y%m%d") }
    }

    let(:view_output) {
      [[statistic_date(dates[0]), 4], [statistic_date(dates[1]), 8], [statistic_date(dates[2]), 6], [statistic_date(dates[3]), 10]]
    }

    # This is what the data looks like that's returned from Google Analytics (GA) via the Legato gem
    # Due to the nature of querying GA, testing this data in an automated fashion is problematc.
    # Sample data structures were created by sending real events to GA from a test instance of
    # Scholarsphere.  The data below are essentially a "cut and paste" from the output of query
    # results from the Legato gem.
    let(:sample_work_pageview_statistics) {
      [
        OpenStruct.new(date: date_strs[0], pageviews: 4),
        OpenStruct.new(date: date_strs[1], pageviews: 8),
        OpenStruct.new(date: date_strs[2], pageviews: 6),
        OpenStruct.new(date: date_strs[3], pageviews: 10),
        # OpenStruct.new(date: date_strs[4], pageviews: 2)
      ]
    }
    describe "cache empty" do
      let(:stats) do
        expect(described_class).to receive(:ga_statistics).and_return(sample_work_pageview_statistics)
        described_class.statistics(work_id, Time.zone.today - 4.days, user_id)
      end

      it "includes cached ga data" do
        expect(described_class.to_flots(stats)).to include(*view_output)
      end

      it "caches data" do
        expect(described_class.to_flots(stats)).to include(*view_output)
        expect(stats.first.user_id).to eq user_id

        # at this point all data should be cached
        allow(described_class).to receive(:ga_statistics).with(Time.zone.today, work_id).and_raise("We should not call Google Analytics All data should be cached!")

        stats2 = described_class.statistics(work_id, Time.zone.today - 5.days)
        expect(described_class.to_flots(stats2)).to include(*view_output)
      end
    end

    describe "cache loaded" do
      let!(:work_view_stat) { described_class.create(date: (Time.zone.today - 5.days).to_datetime, work_id: work_id, work_views: "25") }

      let(:stats) do
        expect(described_class).to receive(:ga_statistics).and_return(sample_work_pageview_statistics)
        described_class.statistics(work_id, Time.zone.today - 5.days)
      end

      it "includes cached data" do
        expect(described_class.to_flots(stats)).to include([work_view_stat.date.to_i * 1000, work_view_stat.work_views], *view_output)
      end
    end
  end
end
