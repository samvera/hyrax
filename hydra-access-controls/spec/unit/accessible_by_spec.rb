require 'spec_helper'

describe "active_fedora/accessible_by" do
  let(:user) {FactoryGirl.build(:ira_instructor)}
  let(:ability) {Ability.new(user)}
  let(:private_obj) {FactoryGirl.create(:asset)}
  let(:public_obj) {FactoryGirl.create(:asset)}
  let(:editable_obj) {FactoryGirl.create(:asset)}

  before do
    private_obj.permissions_attributes = [{ name: "joe_creator", access: "edit", type: "person" }]
    private_obj.save
    public_obj.permissions_attributes = [{ name: "public", access: "read", type: "group" }, { name: "joe_creator", access: "edit", type: "person" }, { name: "calvin_collaborator", access: "edit", type: "person" }]
    public_obj.save
    editable_obj.permissions_attributes = [{ name:"africana-faculty", access: "edit", type: "group" }, {name: "calvin_collaborator", access: "edit", type: "person"}]
    editable_obj.save
    expect(user).to receive(:groups).at_most(:once).and_return(["faculty", "africana-faculty"])
  end

  after do
    ModsAsset.delete_all
  end

  describe "#accsesible_by" do
    it "should return objects readable by the ability" do
      expect(ModsAsset.accessible_by(ability)).to eq [public_obj, editable_obj]
    end
    it "should return object editable by the ability" do
      expect(ModsAsset.accessible_by(ability, :edit)).to eq [editable_obj]
    end
    it "should return only public objects for an anonymous user" do
      expect(ModsAsset.accessible_by(Ability.new(nil))).to eq [public_obj]
    end
  end
end
