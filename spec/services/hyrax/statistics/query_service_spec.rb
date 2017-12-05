RSpec.describe Hyrax::Statistics::QueryService, :clean_repo do
  let(:service) { described_class.new }

  describe "#count" do
    let!(:work) { create_for_repository(:work) }

    subject { service.count }

    it { is_expected.to eq 1 }
  end

  describe "count_by_date_created" do
    let!(:work) { create_for_repository(:work) }

    subject { service.count_by_date_created(start_date, end_date) }

    context "with no start date" do
      let(:start_date) { nil }
      let(:end_date) { nil }

      it { is_expected.to eq 0 }
    end

    context "with no end date" do
      let(:start_date) { 1.day.ago }
      let(:end_date) { nil }

      it { is_expected.to eq 1 }
    end

    context "with an end date" do
      let(:start_date) { 1.day.ago }
      let(:end_date) { Time.zone.now }

      it { is_expected.to eq 1 }
    end
  end

  describe "count_registered" do
    subject { service.count_registered }

    let!(:work) { create_for_repository(:work, read_groups: read_groups) }

    context "when file is private" do
      let(:read_groups) { ["private"] }

      it { is_expected.to eq 0 }
    end

    context "when file is public" do
      let(:read_groups) { ["public"] }

      it { is_expected.to eq 0 }
    end

    context "when file is registered" do
      let(:read_groups) { ["registered"] }

      it { is_expected.to eq 1 }
    end
  end

  describe "count_public" do
    subject { service.count_public }

    let!(:work) { create_for_repository(:work, read_groups: read_groups) }

    context "when file is private" do
      let(:read_groups) { ["private"] }

      it { is_expected.to eq 0 }
    end

    context "when file is public" do
      let(:read_groups) { ["public"] }

      it { is_expected.to eq 1 }
    end

    context "when file is registered" do
      let(:read_groups) { ["registered"] }

      it { is_expected.to eq 0 }
    end
  end

  describe "#count_registered_in_date_range" do
    let(:start_date) { 1.day.ago }
    let(:end_date) { Time.zone.now }

    it "runs a query" do
      allow(service).to receive(:build_date_query).with(start_date, end_date).and_return('date query')
      expect(ActiveFedora::SolrService).to receive(:count)
        .with("date query AND _query_:\"{!field f=read_access_group_ssim}registered\" AND " \
              "(_query_:\"{!raw f=internal_resource_ssim}GenericWork\" OR _query_:\"{!raw f=internal_resource_ssim}RareBooks::Atlas\")")
      service.count_registered_in_date_range(start_date, end_date)
    end
  end

  describe "#count_public_in_date_range" do
    let(:start_date) { 1.day.ago }
    let(:end_date) { Time.zone.now }

    it "is a relation" do
      allow(service).to receive(:build_date_query).with(start_date, end_date).and_return('date query')
      expect(ActiveFedora::SolrService).to receive(:count)
        .with("date query AND _query_:\"{!field f=read_access_group_ssim}public\" AND " \
              "(_query_:\"{!raw f=internal_resource_ssim}GenericWork\" OR _query_:\"{!raw f=internal_resource_ssim}RareBooks::Atlas\")")
      service.count_public_in_date_range(start_date, end_date)
    end
  end
end
