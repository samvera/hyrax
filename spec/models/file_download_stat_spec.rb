# frozen_string_literal: true
RSpec.describe FileDownloadStat, type: :model do
  let(:file_id) { file.id }
  let(:date) { Time.current }
  let(:file_stat) { described_class.new(downloads: "2", date: date, file_id: file_id) }
  let(:file) { mock_model('MockFileSet', id: 99) }

  it "has attributes" do
    expect(file_stat).to respond_to(:downloads)
    expect(file_stat).to respond_to(:date)
    expect(file_stat).to respond_to(:file_id)
    expect(file_stat.file_id).to eq("99")
    expect(file_stat.date.round(0)).to eq(date.round(0))
    expect(file_stat.downloads).to eq(2)
  end

  describe "#statistics" do
    let(:dates) do
      ldates = []
      4.downto(0) { |idx| ldates << (Time.zone.today - idx.day) }
      ldates
    end
    let(:date_strs) do
      dates.map { |date| date.strftime("%Y%m%d") }
    end

    let(:download_output) do
      [[statistic_date(dates[0]), 1], [statistic_date(dates[1]), 1], [statistic_date(dates[2]), 2], [statistic_date(dates[3]), 3]]
    end

    # This is what the data looks like that's returned from Google Analytics (GA) via the Legato gem
    # Due to the nature of querying GA, testing this data in an automated fashion is problematc.
    # Sample data structures were created by sending real events to GA from a test instance of
    # Scholarsphere.  The data below are essentially a "cut and paste" from the output of query
    # results from the Legato gem.
    let(:sample_download_statistics) do
      [
        SpecStatistic.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "hyrax:x920fw85p", date: date_strs[0], totalEvents: "1"),
        SpecStatistic.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "hyrax:x920fw85p", date: date_strs[1], totalEvents: "1"),
        SpecStatistic.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "hyrax:x920fw85p", date: date_strs[2], totalEvents: "2"),
        SpecStatistic.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "hyrax:x920fw85p", date: date_strs[3], totalEvents: "3")
      ]
    end

    describe "cache empty" do
      let(:stats) do
        expect(Hyrax::Analytics).to receive(:page_statistics).and_return(sample_download_statistics)
        described_class.statistics(file, Time.zone.today - 4.days)
      end

      it "includes cached ga data" do
        expect(stats.map(&:to_flot)).to include(*download_output)
      end

      it "caches data" do
        expect(stats.map(&:to_flot)).to include(*download_output)

        # at this point all data should be cached
        allow(Hyrax::Analytics).to receive(:page_statistics).and_raise("We should not call Google Analytics All data should be cached!")
        stats2 = described_class.statistics(file, Time.zone.today - 4.days)
        expect(stats2.map(&:to_flot)).to include(*download_output)
      end
    end

    describe "cache loaded" do
      let!(:file_download_stat) { described_class.create(date: (Time.zone.today - 5.days).to_datetime, file_id: file_id, downloads: "25") }

      let(:stats) do
        expect(Hyrax::Analytics).to receive(:page_statistics).and_return(sample_download_statistics)
        described_class.statistics(file, Time.zone.today - 5.days)
      end

      it "includes cached data" do
        expect(stats.map(&:to_flot)).to include([file_download_stat.date.to_i * 1000, file_download_stat.downloads], *download_output)
      end
    end
  end
end
