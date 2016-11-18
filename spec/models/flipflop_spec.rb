require 'spec_helper'

RSpec.describe Flipflop do
  describe "assign_admin_set?" do
    subject { described_class.assign_admin_set? }
    it { is_expected.to be true }
  end
  describe "enable_mediated_deposit?" do
    subject { described_class.enable_mediated_deposit? }
    it { is_expected.to be false }
  end
end
