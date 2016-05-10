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

  describe "#empty?" do
    subject { relationship.empty? }
    it { is_expected.to be true }
  end
end
