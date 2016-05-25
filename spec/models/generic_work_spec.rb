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
end
