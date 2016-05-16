require 'spec_helper'

describe GenericWork do
  describe ".properties" do
    subject { described_class.properties.keys }
    it { is_expected.to include("has_model", "create_date", "modified_date") }
  end

  describe "basic metadata" do
    it "has dc properties" do
      subject.title = ['foo', 'bar']
      expect(subject.title).to eq ['foo', 'bar']
    end
  end

  describe "created for someone (proxy)" do
    let(:work) { described_class.new(title: ['demoname']) { |gw| gw.apply_depositor_metadata("user") } }
    let(:transfer_to) { create(:user) }

    it "transfers the request" do
      work.on_behalf_of = transfer_to.user_key
      expect(ContentDepositorChangeEventJob).to receive(:perform_later).once
      work.save!
    end
  end

  describe "delegations" do
    let(:work) { described_class.new { |gw| gw.apply_depositor_metadata("user") } }
    let(:proxy_depositor) { create(:user) }
    before do
      work.proxy_depositor = proxy_depositor.user_key
    end
    it "includes proxies" do
      expect(work).to respond_to(:relative_path)
      expect(work).to respond_to(:depositor)
      expect(work.proxy_depositor).to eq proxy_depositor.user_key
    end
  end

  describe "trophies" do
    before do
      u = create(:user)
      @w = described_class.create!(title: ['demoname']) do |gw|
        gw.apply_depositor_metadata(u)
      end
      @t = Trophy.create(user_id: u.id, work_id: @w.id)
    end
    it "has a trophy" do
      expect(Trophy.where(work_id: @w.id).count).to eq 1
    end
    it "removes all trophies when work is deleted" do
      @w.destroy
      expect(Trophy.where(work_id: @w.id).count).to eq 0
    end
  end

  describe "metadata" do
    it "has descriptive metadata" do
      expect(subject).to respond_to(:relative_path)
      expect(subject).to respond_to(:depositor)
      expect(subject).to respond_to(:related_url)
      expect(subject).to respond_to(:based_near)
      expect(subject).to respond_to(:part_of)
      expect(subject).to respond_to(:contributor)
      expect(subject).to respond_to(:creator)
      expect(subject).to respond_to(:title)
      expect(subject).to respond_to(:description)
      expect(subject).to respond_to(:publisher)
      expect(subject).to respond_to(:date_created)
      expect(subject).to respond_to(:date_uploaded)
      expect(subject).to respond_to(:date_modified)
      expect(subject).to respond_to(:subject)
      expect(subject).to respond_to(:language)
      expect(subject).to respond_to(:rights)
      expect(subject).to respond_to(:resource_type)
      expect(subject).to respond_to(:identifier)
    end
  end

  describe "find_by_date_created" do
    let!(:work) { create(:generic_work) }
    subject { described_class.find_by_date_created(start_date, end_date) }

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
      let(:end_date) { Time.zone.now }
      it { is_expected.to eq [work] }
    end
  end

  describe "where_access_is" do
    subject { described_class.where_access_is access_level }
    let!(:work) { create(:generic_work, read_groups: read_groups) }

    context "when file is private" do
      let(:read_groups) { ["private"] }
      context "when access level is private" do
        let(:access_level) { 'private' }
        it { is_expected.to eq [work] }
      end
      context "when access level is public" do
        let(:access_level) { 'public' }
        it { is_expected.to eq [] }
      end
      context "when access level is registered" do
        let(:access_level) { 'registered' }
        it { is_expected.to eq [] }
      end
    end

    context "when file is public" do
      let(:read_groups) { ["public"] }
      context "when access level is private" do
        let(:access_level) { 'private' }
        it { is_expected.to eq [] }
      end
      context "when access level is public" do
        let(:access_level) { 'public' }
        it { is_expected.to eq [work] }
      end
      context "when access level is registered" do
        let(:access_level) { 'registered' }
        it { is_expected.to eq [] }
      end
    end

    context "when file is registered" do
      let(:read_groups) { ["registered"] }
      context "when access level is private" do
        let(:access_level) { 'private' }
        it { is_expected.to eq [] }
      end
      context "when access level is public" do
        let(:access_level) { 'public' }
        it { is_expected.to eq [] }
      end
      context "when access level is registered" do
        let(:access_level) { 'registered' }
        it { is_expected.to eq [work] }
      end
    end
  end

  describe "where_private" do
    it "calls where_access_is with private" do
      expect(described_class).to receive(:where_access_is).with('private')
      described_class.where_private
    end
  end

  describe "where_registered" do
    it "calls where_access_is with registered" do
      expect(described_class).to receive(:where_access_is).with('registered')
      described_class.where_registered
    end
  end

  describe "where_public" do
    it "calls where_access_is with public" do
      expect(described_class).to receive(:where_access_is).with('public')
      described_class.where_public
    end
  end
end
