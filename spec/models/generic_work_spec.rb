require 'spec_helper'

describe GenericWork do

  describe "Using services in Hydra::PCDM" do
    # Ideally we shouldn't need to call Hydra::PCDM
    # from Sufia. For now I am because some of the
    # functionality that I want to test has not been
    # implemented in Hydra::Works.
    collection = Hydra::PCDM::Collection.create
    object1 = Hydra::PCDM::Object.create
    object2 = Hydra::PCDM::Object.create
    Hydra::PCDM::AddObjectToCollection.call(collection, object1)
    Hydra::PCDM::AddObjectToCollection.call(collection, object2)
    objects = Hydra::PCDM::GetObjectsFromCollection.call(collection)
  end

  describe "Using services in Hydra::Works" do
    gf = Hydra::Works::GenericFile::Base.create
    path = fixture_path + '/world.png'
    Hydra::Works::UploadFileToGenericFile.call(gf, path)
  end

  describe ".properties" do
    subject { described_class.properties.keys }
    it { is_expected.to include("has_model", "create_date", "modified_date") }
  end

  describe "basic metadata" do
    it "should have dc properties" do
      subject.title = ['foo', 'bar']
      expect(subject.title).to eq ['foo', 'bar']
    end
  end

  describe "created for someone (proxy)" do
    let(:work) { GenericWork.new.tap {|gw| gw.apply_depositor_metadata("user")} }
    let(:transfer_to) { FactoryGirl.find_or_create(:jill) }

    it "transfers the request" do
      work.on_behalf_of = transfer_to.user_key
      stub_job = double('change depositor job')
      allow(ContentDepositorChangeEventJob).to receive(:new).and_return(stub_job)
      expect(Sufia.queue).to receive(:push).with(stub_job).once.and_return(true)
      work.save!
    end
  end

  describe "delegations" do
    let(:work) { GenericWork.new.tap {|gw| gw.apply_depositor_metadata("user")} }
    let(:proxy_depositor) { FactoryGirl.find_or_create(:jill) }
    before do
      work.proxy_depositor = proxy_depositor.user_key
    end
    it "should include proxies" do
      expect(work).to respond_to(:relative_path)
      expect(work).to respond_to(:depositor)
      expect(work.proxy_depositor).to eq proxy_depositor.user_key
    end
  end

  describe "trophies" do
    before do
      u = FactoryGirl.find_or_create(:jill)
      @w = GenericWork.new.tap do |gw|
        gw.apply_depositor_metadata(u)
        gw.save!
      end
      @t = Trophy.create(user_id: u.id, generic_work_id: @w.id)
    end
    it "should have a trophy" do
      expect(Trophy.where(generic_work_id: @w.id).count).to eq 1
    end
    it "should remove all trophies when work is deleted" do
      @w.destroy
      expect(Trophy.where(generic_work_id: @w.id).count).to eq 0
    end
  end

  describe "metadata" do
    it "should have descriptive metadata" do
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

