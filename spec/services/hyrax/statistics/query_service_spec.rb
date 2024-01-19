# frozen_string_literal: true
RSpec.describe Hyrax::Statistics::QueryService, :clean_repo, :active_fedora do
  let(:service) { described_class.new }

  describe "#count" do
    let!(:work) { create(:generic_work) }

    subject { service.count }

    it { is_expected.to eq 1 }
  end

  describe "find_by_date_created" do
    let!(:work) { create(:generic_work) }

    subject { service.find_by_date_created(start_date, end_date) }

    context "with no start date" do
      let(:start_date) { nil }
      let(:end_date) { nil }

      it { is_expected.to eq [] }
    end

    context "with no end date" do
      let(:start_date) { 1.day.ago }
      let(:end_date) { nil }

      it { is_expected.to eq [work] }
    end

    context "with an end date" do
      let(:start_date) { 1.day.ago }
      let(:end_date) { 1.second.since(Time.zone.now) }

      it { is_expected.to eq [work] }
    end
  end

  describe "where_registered" do
    subject { service.where_registered.to_a }

    let!(:work) { create(:generic_work, read_groups: read_groups) }

    context "when file is private" do
      let(:read_groups) { ["private"] }

      it { is_expected.to eq [] }
    end

    context "when file is public" do
      let(:read_groups) { ["public"] }

      it { is_expected.to eq [] }
    end

    context "when file is registered" do
      let(:read_groups) { ["registered"] }

      it { is_expected.to eq [work] }
    end
  end

  describe "where_public" do
    subject { service.where_public.to_a }

    let!(:work) { create(:generic_work, read_groups: read_groups) }

    context "when file is private" do
      let(:read_groups) { ["private"] }

      it { is_expected.to eq [] }
    end

    context "when file is public" do
      let(:read_groups) { ["public"] }

      it { is_expected.to eq [work] }
    end

    context "when file is registered" do
      let(:read_groups) { ["registered"] }

      it { is_expected.to eq [] }
    end
  end

  describe "#find_registered_in_date_range", unless: Hyrax.config.use_valkyrie? do
    subject { service.find_registered_in_date_range(start_date, end_date) }

    let(:start_date) { 1.day.ago }
    let(:end_date) { 1.second.since(Time.zone.now) }

    it "is a relation" do
      allow(service).to receive(:build_date_query).with(start_date, end_date).and_return('date query')
      expect(subject).to be_kind_of ActiveFedora::Relation
      expect(subject.values).to eq(where: ["(date query)", "_query_:\"{!field f=read_access_group_ssim}registered\""])
    end
  end

  describe "#find_public_in_date_range", unless: Hyrax.config.use_valkyrie? do
    subject { service.find_public_in_date_range(start_date, end_date) }

    let(:start_date) { 1.day.ago }
    let(:end_date) { 1.second.since(Time.zone.now) }

    it "is a relation" do
      allow(service).to receive(:build_date_query).with(start_date, end_date).and_return('date query')
      expect(subject).to be_kind_of ActiveFedora::Relation
      expect(subject.values).to eq(where: ["(date query)", "_query_:\"{!field f=read_access_group_ssim}public\""])
    end
  end
end
