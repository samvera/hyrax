require 'spec_helper'

describe "active_fedora/accessible_by" do
  let(:user) {FactoryGirl.build(:ira_instructor)}
  let(:ability) {Ability.new(user)}
  let(:private_obj) {FactoryGirl.create(:default_access_asset)}
  let(:public_obj) {FactoryGirl.create(:open_access_asset)}
  let(:editable_obj) {FactoryGirl.create(:group_edit_asset)}

  before do
    expect(user).to receive(:groups).at_most(:once).and_return(user.roles)
    ModsAsset.delete_all
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
