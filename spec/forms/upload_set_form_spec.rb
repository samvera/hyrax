require 'spec_helper'

describe Sufia::UploadSetForm do
  let(:form) { described_class.new(model, ability) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user, display_name: 'Jill Z. User') }
  let(:model) { UploadSet.new }

  describe "#creator" do
    subject { form.creator }
    it { is_expected.to eq ['Jill Z. User'] }
  end
end
