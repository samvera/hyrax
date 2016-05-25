describe FileDownloadStat, type: :model do
  let(:file_id) { "99" }
  let(:date) { Time.current }
  let(:file_stat) { described_class.create(downloads: "2", date: date, file_id: file_id) }

  it "has attributes" do
    expect(file_stat).to respond_to(:downloads)
    expect(file_stat).to respond_to(:date)
    expect(file_stat).to respond_to(:file_id)
    expect(file_stat.file_id).to eq("99")
    expect(file_stat.date).to eq(date)
    expect(file_stat.downloads).to eq(2)
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

    let(:download_output) {
      [[statistic_date(dates[0]), 1], [statistic_date(dates[1]), 1], [statistic_date(dates[2]), 2], [statistic_date(dates[3]), 3]]
    }

    # This is what the data looks like that's returned from Google Analytics (GA) via the Legato gem
    # Due to the nature of querying GA, testing this data in an automated fashion is problematc.
    # Sample data structures were created by sending real events to GA from a test instance of
    # Scholarsphere.  The data below are essentially a "cut and paste" from the output of query
    # results from the Legato gem.
    let(:sample_download_statistics) {
      [
        OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: date_strs[0], totalEvents: "1"),
        OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: date_strs[1], totalEvents: "1"),
        OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: date_strs[2], totalEvents: "2"),
        OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: date_strs[3], totalEvents: "3"),
        # OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: date_strs[4], totalEvents: "5"),
      ]
    }

    describe "cache empty" do
      let(:stats) do
        expect(described_class).to receive(:ga_statistics).and_return(sample_download_statistics)
        described_class.statistics(file_id, Time.zone.today - 4.days)
      end

      it "includes cached ga data" do
        expect(described_class.to_flots(stats)).to include(*download_output)
      end

      it "caches data" do
        expect(described_class.to_flots(stats)).to include(*download_output)

        # at this point all data should be cached
        allow(described_class).to receive(:ga_statistics).with(Time.zone.today, file_id).and_raise("We should not call Google Analytics All data should be cached!")

        stats2 = described_class.statistics(file_id, Time.zone.today - 4.days)
        expect(described_class.to_flots(stats2)).to include(*download_output)
      end
    end

    describe "cache loaded" do
      let!(:file_download_stat) { described_class.create(date: (Time.zone.today - 5.days).to_datetime, file_id: file_id, downloads: "25") }

      let(:stats) do
        expect(described_class).to receive(:ga_statistics).and_return(sample_download_statistics)
        described_class.statistics(file_id, Time.zone.today - 5.days)
      end

      it "includes cached data" do
        expect(described_class.to_flots(stats)).to include([file_download_stat.date.to_i * 1000, file_download_stat.downloads], *download_output)
      end
    end
  end
end
