require 'spec_helper'

describe Hydra::FutureDateValidator do
  let(:future_date) { Date.today + 2 }
  let(:past_date) { Date.today - 2 }
  let(:validator) { Hydra::FutureDateValidator.new(attributes: [:embargo_release_date, :lease_expiration_date]) }
  before do
    validator.validate(subject)
  end
 
  context "when date is valid" do
    subject { ModsAsset.new(embargo_release_date: future_date) }
    its(:errors) { should be_empty }
  end

  context "when date is invalid" do
    subject { ModsAsset.new(lease_expiration_date: past_date) }
    it "has errors" do
      expect(subject.errors[:lease_expiration_date]).to eq ['Must be a future date']
    end
  end
end
