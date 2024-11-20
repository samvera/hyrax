# frozen_string_literal: true
RSpec.describe Hyrax::WorkUsage, type: :model do
  let!(:work) { valkyrie_create(:monograph, date_uploaded: date_uploaded) }
  let(:date_uploaded) { Hyrax::TimeService.time_in_utc - 4.days }

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

  # This is what the data looks like that's returned from Google Analytics (GA) via the Legato gem
  # Due to the nature of querying GA, testing this data in an automated fashion is problematc.
  # Sample data structures were created by sending real events to GA from a test instance of
  # Scholarsphere.  The data below are essentially a "cut and paste" from the output of query
  # results from the Legato gem.

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
    allow(Hyrax::Analytics).to receive(:page_statistics).and_return(sample_pageview_statistics)
    described_class.new(work.id)
  end

  describe "#initialize" do
    it "sets the model" do
      expect(usage.model).to eq work
    end

    it "sets the created date" do
      expect(usage.created).to eq(work.date_uploaded)
    end
  end

  describe "#to_s" do
    let(:work) { valkyrie_create(:monograph, title: ['Butter sculpture']) }

    subject { usage.to_s }

    it { is_expected.to eq 'Butter sculpture' }
  end

  describe "#to_flot" do
    let(:flots) { usage.to_flot }

    it "returns an array of hashes for use with JQuery Flot" do
      expect(flots[0][:label]).to eq("Pageviews")
      expect(flots[0][:data]).to include(*view_output)
    end
  end

  describe "#total_pageviews" do
    it "counts the total number of pageviews" do
      expect(usage.total_pageviews).to eq(30)
    end
  end

  describe "#created" do
    let!(:system_timezone) { ENV['TZ'] }
    let(:create_date) { Time.zone.parse('2014-01-02 12:00:00').iso8601 }
    let(:date_uploaded) { create_date }

    before do
      ENV['TZ'] = 'UTC'
    end

    after do
      ENV['TZ'] = system_timezone
    end

    describe "analytics start date set" do
      let(:earliest) { Time.zone.parse('2014-01-02 12:00:00').iso8601 }

      before do
        Hyrax.config.analytic_start_date = earliest
      end

      describe "create date before earliest date set" do
        let(:usage) do
          described_class.new(work.id)
        end

        it "sets the created date to the earliest date not the created date" do
          expect(usage.created).to eq(earliest)
        end
      end

      describe "create date after earliest" do
        let(:usage) do
          Hyrax.config.analytic_start_date = earliest
          described_class.new(work.id)
        end
        let(:date_uploaded) { Hyrax::TimeService.time_in_utc - 4.days }

        it "sets the created date to the earliest date not the created date" do
          expect(usage.created).to eq(work.date_uploaded)
        end
      end
    end
    describe "start date not set" do
      before do
        Hyrax.config.analytic_start_date = nil
      end

      let(:usage) do
        described_class.new(work.id)
      end

      it "sets the created date to the earliest date not the created date" do
        expect(usage.created).to eq(create_date)
      end
    end
  end

  describe "on a migrated work" do
    let(:date_uploaded) { Time.zone.parse "2014-12-31" }
    let(:work_migrated) { valkyrie_create(:monograph, date_uploaded: date_uploaded) }

    let(:usage) do
      described_class.new(work_migrated.id)
    end

    it "uses the date_uploaded for analytics" do
      expect(usage.created).to eq(date_uploaded)
    end
  end
end
