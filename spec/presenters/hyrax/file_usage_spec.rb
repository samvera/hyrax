# frozen_string_literal: true
RSpec.describe Hyrax::FileUsage, type: :model do
  let(:user) { build(:user) }
  let(:file) do
    create(:file_set, user: user)
  end

  let(:dates) do
    ldates = []
    4.downto(0) { |idx| ldates << (Time.zone.today - idx.day) }
    ldates
  end
  let(:date_strs) do
    ldate_strs = []
    dates.each { |date| ldate_strs << date.strftime("%Y%m%d") }
    ldate_strs
  end

  let(:view_output) do
    [[statistic_date(dates[0]), 4], [statistic_date(dates[1]), 8], [statistic_date(dates[2]), 6], [statistic_date(dates[3]), 10], [statistic_date(dates[4]), 2]]
  end

  let(:download_output) do
    [[statistic_date(dates[0]), 1], [statistic_date(dates[1]), 1], [statistic_date(dates[2]), 2], [statistic_date(dates[3]), 3], [statistic_date(dates[4]), 5]]
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
      SpecStatistic.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "hyrax:x920fw85p", date: date_strs[3], totalEvents: "3"),
      SpecStatistic.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "hyrax:x920fw85p", date: date_strs[4], totalEvents: "5")
    ]
  end

  let(:sample_pageview_statistics) do
    [
      SpecStatistic.new(date: date_strs[0], pageviews: 4),
      SpecStatistic.new(date: date_strs[1], pageviews: 8),
      SpecStatistic.new(date: date_strs[2], pageviews: 6),
      SpecStatistic.new(date: date_strs[3], pageviews: 10),
      SpecStatistic.new(date: date_strs[4], pageviews: 2)
    ]
  end

  let(:usage) do
    allow_any_instance_of(FileSet).to receive(:create_date).and_return((Time.zone.today - 4.days).to_s)
    allow(FileDownloadStat).to receive(:ga_statistics).and_return(sample_download_statistics)
    allow(FileViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
    described_class.new(file.id)
  end

  describe "#initialize" do
    it "sets the model" do
      expect(usage.model).to eq file
    end
  end

  describe "#to_flot" do
    let(:flots) { usage.to_flot }

    it "returns an array of hashes for use with JQuery Flot" do
      expect(flots[0][:label]).to eq("Pageviews")
      expect(flots[1][:label]).to eq("Downloads")
      expect(flots[0][:data]).to include(*view_output)
      expect(flots[1][:data]).to include(*download_output)
    end
  end

  describe "#created" do
    let!(:system_timezone) { ENV['TZ'] }

    before do
      ENV['TZ'] = 'UTC'
    end

    after do
      ENV['TZ'] = system_timezone
    end

    it "sets the created date" do
      expect(usage.created).to eq(file.create_date)
    end

    it "counts the total numver of downloads" do
      expect(usage.total_downloads).to eq(12)
    end

    it "counts the total numver of pageviews" do
      expect(usage.total_pageviews).to eq(30)
    end

    context "when the analytics start date is set" do
      let(:earliest) { DateTime.new(2014, 1, 2).iso8601 }
      let(:create_date) { DateTime.new(2014, 1, 1).iso8601 }

      before do
        Hyrax.config.analytic_start_date = earliest
      end

      describe "create date before earliest date set" do
        let(:usage) do
          allow_any_instance_of(FileSet).to receive(:create_date).and_return(create_date.to_s)
          described_class.new(file.id)
        end

        it "sets the created date to the earliest date not the created date" do
          expect(usage.created).to eq(earliest)
        end
      end

      describe "create date after earliest" do
        let(:usage) do
          allow_any_instance_of(FileSet).to receive(:create_date).and_return((Time.zone.today - 4.days).to_s)
          Hyrax.config.analytic_start_date = earliest
          described_class.new(file.id)
        end

        it "sets the created date to the earliest date not the created date" do
          expect(usage.created).to eq(file.create_date)
        end
      end
    end

    context "when the start date is not set" do
      before do
        Hyrax.config.analytic_start_date = nil
      end
      let(:create_date) { DateTime.new(2014, 1, 1).iso8601 }

      let(:usage) do
        allow_any_instance_of(FileSet).to receive(:create_date).and_return(create_date.to_s)
        described_class.new(file.id)
      end

      it "sets the created date to the earliest date not the created date" do
        expect(usage.created).to eq(create_date)
      end
    end
  end

  describe "on a migrated file" do
    let(:date_uploaded) { "2014-12-31" }
    let(:file_migrated) do
      create(:file_set, date_uploaded: date_uploaded, user: user)
    end

    let(:usage) do
      described_class.new(file_migrated.id)
    end

    it "uses the date_uploaded for analytics" do
      expect(usage.created).to eq(date_uploaded)
    end
  end
end
