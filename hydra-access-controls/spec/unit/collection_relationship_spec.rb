require 'spec_helper'

describe Hydra::AccessControl::CollectionRelationship do
  let(:access_control) { Hydra::AccessControl.new }
  let(:relationship) { access_control.relationship }

  describe "#==" do
    subject { relationship }
    it "compares to array" do
      expect(subject).to eq []
    end
  end

  describe "#first" do
    let!(:one) { relationship.build(name: 'user1', type: 'person', access: 'read') }
    let!(:two) { relationship.build(name: 'user2', type: 'person', access: 'read') }
    subject { relationship.first }
    it { is_expected.to be one }
  end

  describe "#last" do
    let!(:one) { relationship.build(name: 'user1', type: 'person', access: 'read') }
    let!(:two) { relationship.build(name: 'user2', type: 'person', access: 'read') }
    subject { relationship.last }
    it { is_expected.to be two }
  end

  describe "#include?" do
    let!(:one) { relationship.build(name: 'user1', type: 'person', access: 'read') }
    let(:two) { Hydra::AccessControls::Permission.new(name: 'user2', type: 'person', access: 'read') }
    it 'returns a boolean' do
      expect(relationship).to include(one)
      expect(relationship).not_to include(two)
    end
  end

  describe "#empty?" do
    subject { relationship.empty? }
    it { is_expected.to be true }
  end

  describe "#each" do
    let!(:one) { relationship.build(name: 'user1', type: 'person', access: 'read') }
    let!(:two) { relationship.build(name: 'user2', type: 'person', access: 'read') }
    let(:counter) { double }
    it "invokes the block with each object" do
      expect(counter).to receive(:check).with(one)
      expect(counter).to receive(:check).with(two)
      relationship.each { |o| counter.check(o) }
    end
  end

  describe "#map" do
    let!(:one) { relationship.build(name: 'user1', type: 'person', access: 'read') }
    let!(:two) { relationship.build(name: 'user2', type: 'person', access: 'read') }
    it "maps each element through the block" do
      expect(relationship.map { |o| o.agent_name }).to eq ['user1', 'user2']
    end
  end

  describe "#detect" do
    let!(:one) { relationship.build(name: 'user1', type: 'person', access: 'read') }
    let!(:two) { relationship.build(name: 'user2', type: 'person', access: 'read') }
    it "finds the first match" do
      expect(relationship.detect { |o| o.agent_name == 'user2' }).to eq two
    end
  end

  describe "#find" do
    before do
      access_control.save!
    end
    let!(:one) { relationship.create(name: 'user1', type: 'person', access: 'read') }
    let!(:two) { relationship.create(name: 'user2', type: 'person', access: 'read') }
    context "when the id is in the set" do
      it "finds matches by id" do
        expect(relationship.find(two.id)).to eq two
      end
    end
    context "when the id is not the set" do
      it "raises an error" do
        expect { relationship.find('999') }.to raise_error ArgumentError, "requested ACL (999) is not a member of #{access_control.id}"
      end
    end
  end

  describe "#any?" do
    let!(:one) { relationship.build(name: 'user1', type: 'person', access: 'read') }
    let!(:two) { relationship.build(name: 'user2', type: 'person', access: 'read') }
    it "invokes the block with each object" do
      expect(relationship.any? { |o| o.agent_name == 'user2' }).to be true
    end
  end

  describe "#all?" do
    let!(:one) { relationship.build(name: 'user1', type: 'person', access: 'read') }
    let!(:two) { relationship.build(name: 'user2', type: 'person', access: 'read') }
    let(:counter) { double }
    context "when all members satisfy the condition" do
      subject { relationship.all? { |o| o.type == 'person' } }
      it { is_expected.to be true }
    end
    context "when some members don't satisfy the condition" do
      subject { relationship.all? { |o| o.agent_name == 'user1' } }
      it { is_expected.to be false }
    end
  end

  describe "#destroy_all" do
    before do
      access_control.save!
    end
    let!(:one) { relationship.create(name: 'user1', type: 'person', access: 'read') }
    let!(:two) { relationship.create(name: 'user2', type: 'person', access: 'read') }
    it "invokes the block with each object" do
      expect { relationship.destroy_all }.to change { Hydra::AccessControls::Permission.count}.by(-2)
    end
  end
end
