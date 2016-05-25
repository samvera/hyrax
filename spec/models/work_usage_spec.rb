describe WorkUsage, type: :model do
  let!(:work) do
    GenericWork.create(id: '12345', title: ['bilbo work 1']) do |work|
      work.apply_depositor_metadata("gordonl")
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

  let(:view_output) {
    [[statistic_date(dates[0]), 4], [statistic_date(dates[1]), 8], [statistic_date(dates[2]), 6], [statistic_date(dates[3]), 10], [statistic_date(dates[4]), 2]]
  }

  # This is what the data looks like that's returned from Google Analytics (GA) via the Legato gem
  # Due to the nature of querying GA, testing this data in an automated fashion is problematc.
  # Sample data structures were created by sending real events to GA from a test instance of
  # Scholarsphere.  The data below are essentially a "cut and paste" from the output of query
  # results from the Legato gem.

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
    allow_any_instance_of(GenericWork).to receive(:create_date).and_return((Time.zone.today - 4.days).to_s)
    expect(WorkViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
    described_class.new(work.id)
  }

  describe "#initialize" do
    it "sets the id" do
      expect(usage.id).to eq(work.id)
    end

    it "sets the path" do
      expect(usage.path).to eq("/concern/generic_works/#{URI.encode(work.id, '/')}")
    end

    it "sets the created date" do
      expect(usage.created).to eq(work.create_date)
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

    it "counts the total number of pageviews" do
      expect(usage.total_pageviews).to eq(30)
    end

    it "returns an array of hashes for use with JQuery Flot" do
      expect(usage.to_flot[0][:label]).to eq("Pageviews")
      expect(usage.to_flot[0][:data]).to include(*view_output)
    end

    let(:create_date) { Time.zone.parse('2014-01-02 12:00:00').iso8601 }

    describe "analytics start date set" do
      let(:earliest) { Time.zone.parse('2014-01-02 12:00:00').iso8601 }

      before do
        Sufia.config.analytic_start_date = earliest
      end

      describe "create date before earliest date set" do
        let(:usage) {
          allow_any_instance_of(GenericWork).to receive(:create_date).and_return(create_date.to_s)
          expect(WorkViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
          described_class.new(work.id)
        }
        it "sets the created date to the earliest date not the created date" do
          expect(usage.created).to eq(earliest)
        end
      end

      describe "create date after earliest" do
        let(:usage) {
          allow_any_instance_of(GenericWork).to receive(:create_date).and_return((Time.zone.today - 4.days).to_s)
          expect(WorkViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
          Sufia.config.analytic_start_date = earliest
          described_class.new(work.id)
        }
        it "sets the created date to the earliest date not the created date" do
          expect(usage.created).to eq(work.create_date)
        end
      end
    end
    describe "start date not set" do
      before do
        Sufia.config.analytic_start_date = nil
      end

      let(:usage) {
        allow_any_instance_of(GenericWork).to receive(:create_date).and_return(create_date.to_s)
        expect(WorkViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
        described_class.new(work.id)
      }
      it "sets the created date to the earliest date not the created date" do
        expect(usage.created).to eq(create_date)
      end
    end
  end

  describe "on a migrated work" do
    let(:date_uploaded) { "2014-12-31" }

    let(:work_migrated) do
      GenericWork.create(id: '6789', title: ['bilbo work 2']) do |work|
        work.apply_depositor_metadata("gordonl")
        work.date_uploaded = date_uploaded
        work.save
      end
    end

    let(:usage) {
      expect(WorkViewStat).to receive(:ga_statistics).and_return(sample_pageview_statistics)
      described_class.new(work_migrated.id)
    }

    it "uses the date_uploaded for analytics" do
      expect(usage.created).to eq(date_uploaded)
    end
  end
end
