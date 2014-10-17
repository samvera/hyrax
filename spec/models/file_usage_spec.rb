require 'spec_helper'

describe FileUsage do

  before :all do
    @file = GenericFile.new
    @file.apply_depositor_metadata("awead")
    @file.save
  end

  after :all do
    @file.delete
  end

  # This is what the data looks like that's returned from Google Analytics (GA) via the Legato gem
  # Due to the nature of querying GA, testing this data in an automated fashion is problematc.
  # Sample data structures were created by sending real events to GA from a test instance of 
  # Scholarsphere.  The data below are essentially a "cut and paste" from the output of query
  # results from the Legato gem.

  let(:sample_download_statistics) {
    [
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: "20140101", totalEvents: "1"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: "20140102", totalEvents: "1"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: "20140103", totalEvents: "2"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: "20140104", totalEvents: "3"),
      OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:x920fw85p", date: "20140105", totalEvents: "5"),
    ]
  }

  let(:sample_pageview_statistics) {
    [
      OpenStruct.new(date: '20140101', pageviews: 4),
      OpenStruct.new(date: '20140102', pageviews: 8),
      OpenStruct.new(date: '20140103', pageviews: 6),
      OpenStruct.new(date: '20140104', pageviews: 10),
      OpenStruct.new(date: '20140105', pageviews: 2)
    ]
  }

  let(:usage) {
    allow_any_instance_of(FileUsage).to receive(:download_statistics).and_return(sample_download_statistics)
    allow_any_instance_of(FileUsage).to receive(:pageview_statistics).and_return(sample_pageview_statistics)
    FileUsage.new(@file.id)
  }

  describe "#initialize" do

    it "should set the id" do
      expect(usage.id).to eq(@file.pid)
    end

    it "should set the path" do
      expect(usage.path).to eq("/files/#{Sufia::Noid.noidify(@file.id)}")
    end

    it "should set the created date" do
      expect(usage.created).to eq(DateTime.parse(@file.create_date))
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
      expect(usage.to_flot[0][:data]).to include([1388534400000, 4], [1388620800000, 8], [1388707200000, 6], [1388793600000, 10], [1388880000000, 2]) 
      expect(usage.to_flot[1][:data]).to include([1388534400000, 1], [1388620800000, 1], [1388707200000, 2], [1388793600000, 3],  [1388880000000, 5])
    end

    let(:create_date) {DateTime.new(2014, 01, 01)}

    describe "analytics start date set" do
      let(:earliest) {
        DateTime.new(2014, 01, 02)
      }

      before do
        Sufia.config.analytic_start_date = earliest
      end

      describe "create date before earliest date set" do
        let(:usage) {
          allow_any_instance_of(GenericFile).to receive(:create_date).and_return(create_date.to_s)
          allow_any_instance_of(FileUsage).to receive(:download_statistics).and_return(sample_download_statistics)
          allow_any_instance_of(FileUsage).to receive(:pageview_statistics).and_return(sample_pageview_statistics)
          FileUsage.new(@file.id)
        }
        it "should set the created date to the earliest date not the created date" do
          expect(usage.created).to eq(earliest)
        end

      end

      describe "create date after earliest" do
        let(:usage) {
          allow_any_instance_of(FileUsage).to receive(:download_statistics).and_return(sample_download_statistics)
          allow_any_instance_of(FileUsage).to receive(:pageview_statistics).and_return(sample_pageview_statistics)
          Sufia.config.analytic_start_date = earliest
          FileUsage.new(@file.id)
        }
        it "should set the created date to the earliest date not the created date" do
          expect(usage.created).to eq(@file.create_date)
        end
      end
    end
    describe "start date not set" do
      before do
        Sufia.config.analytic_start_date = nil
      end

      let(:usage) {
        allow_any_instance_of(GenericFile).to receive(:create_date).and_return(create_date.to_s)
        allow_any_instance_of(FileUsage).to receive(:download_statistics).and_return(sample_download_statistics)
        allow_any_instance_of(FileUsage).to receive(:pageview_statistics).and_return(sample_pageview_statistics)
        FileUsage.new(@file.id)
      }
      it "should set the created date to the earliest date not the created date" do
        expect(usage.created).to eq(create_date)
      end

    end
  end

end
