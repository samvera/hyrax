require 'spec_helper'

describe FileUsage, :type => :model do

  let(:file) do
    GenericFile.new.tap do |file|
      file.apply_depositor_metadata("awead")
      file.save
    end
  end

  let(:dates) {
    ldates = []
    4.downto(0) {|idx| ldates << (Date.today-idx.day) }
    ldates
  }
  let(:date_strs) {
    ldate_strs = []
    dates.each {|date| ldate_strs << date.strftime("%Y%m%d") }
    ldate_strs
  }

  let(:view_output) {
    [[statistic_date(dates[0]), 4], [statistic_date(dates[1]), 8], [statistic_date(dates[2]), 6], [statistic_date(dates[3]), 10], [statistic_date(dates[4]), 2]]
  }

  let(:download_output) {
    [[statistic_date(dates[0]), 1], [statistic_date(dates[1]), 1], [statistic_date(dates[2]), 2], [statistic_date(dates[3]), 3],  [statistic_date(dates[4]), 5]]
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
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: date_strs[4], totalEvents: "5"),
    ]
  }

  let(:sample_pageview_statistics) {
    [
      OpenStruct.new(date: date_strs[0], pageviews: 4),
      OpenStruct.new(date: date_strs[1], pageviews: 8),
      OpenStruct.new(date: date_strs[2], pageviews: 6),
      OpenStruct.new(date: date_strs[3], pageviews: 10),
      OpenStruct.new(date: date_strs[4], pageviews: 2)
    ]
  }

  let(:usage) {
    allow_any_instance_of(GenericFile).to receive(:create_date).and_return((Date.today-4.day).to_s)
    expect(FileDownloadStat).to receive(:ga_statistics).and_return(sample_download_statistics)
    expect(FileViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
    FileUsage.new(file.id)
  }

  describe "#initialize" do

    it "should set the id" do
      expect(usage.id).to eq(file.id)
    end

    it "should set the path" do
      expect(usage.path).to eq("/files/#{URI.encode(file.id, '/')}")
    end

    it "should set the created date" do
      expect(usage.created).to eq(file.create_date)
    end

  end

  describe "statistics" do

    before(:all) do
      @system_timezone = ENV['TZ']
      ENV['TZ'] = 'UTC'
    end

    after(:all) do
      ENV['TZ'] = @system_timezone
    end

    it "should count the total numver of downloads" do
      expect(usage.total_downloads).to eq(12)
    end

    it "should count the total numver of pageviews" do
      expect(usage.total_pageviews).to eq(30)
    end

    it "should return an array of hashes for use with JQuery Flot" do
      expect(usage.to_flot[0][:label]).to eq("Pageviews")
      expect(usage.to_flot[1][:label]).to eq("Downloads")
      expect(usage.to_flot[0][:data]).to include(*view_output)
      expect(usage.to_flot[1][:data]).to include(*download_output)
    end

    let(:create_date) { DateTime.new(2014, 01, 01).iso8601 }

    describe "analytics start date set" do
      let(:earliest) { DateTime.new(2014, 01, 02).iso8601 }

      before do
        Sufia.config.analytic_start_date = earliest
      end

      describe "create date before earliest date set" do
        let(:usage) {
          allow_any_instance_of(GenericFile).to receive(:create_date).and_return(create_date.to_s)
          expect(FileDownloadStat).to receive(:ga_statistics).and_return(sample_download_statistics)
          expect(FileViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
          FileUsage.new(file.id)
        }
        it "should set the created date to the earliest date not the created date" do
          expect(usage.created).to eq(earliest)
        end

      end

      describe "create date after earliest" do
        let(:usage) {
          allow_any_instance_of(GenericFile).to receive(:create_date).and_return((Date.today-4.day).to_s)
          expect(FileDownloadStat).to receive(:ga_statistics).and_return(sample_download_statistics)
          expect(FileViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
          Sufia.config.analytic_start_date = earliest
          FileUsage.new(file.id)
        }
        it "should set the created date to the earliest date not the created date" do
          expect(usage.created).to eq(file.create_date)
        end
      end
    end
    describe "start date not set" do
      before do
        Sufia.config.analytic_start_date = nil
      end

      let(:usage) {
        allow_any_instance_of(GenericFile).to receive(:create_date).and_return(create_date.to_s)
        expect(FileDownloadStat).to receive(:ga_statistics).and_return(sample_download_statistics)
        expect(FileViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
        FileUsage.new(file.id)
      }
      it "should set the created date to the earliest date not the created date" do
        expect(usage.created).to eq(create_date)
      end

    end
  end

  describe "on a migrated file" do 
    let(:date_uploaded) { "2014-12-31" }

    let(:file_migrated) do
      GenericFile.new.tap do |file|
        file.apply_depositor_metadata("awead")
        file.date_uploaded = date_uploaded
        file.save
      end
    end

    let(:usage) {
      expect(FileDownloadStat).to receive(:ga_statistics).and_return(sample_download_statistics)
      expect(FileViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
      FileUsage.new(file_migrated.id)
    }

    it "should use the date_uploaded for analytics" do
      expect(usage.created).to eq(date_uploaded)
    end
  end

end
