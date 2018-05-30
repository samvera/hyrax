RSpec.describe Flipflop do
  describe "assign_admin_set?" do
    subject { described_class.assign_admin_set? }

    it "defaults to true" do
      is_expected.to be true
    end
  end

  describe "proxy_deposit?" do
    subject { described_class.proxy_deposit? }

    it "defaults to true" do
      is_expected.to be true
    end
  end

  describe "transfer_works?" do
    subject { described_class.transfer_works? }

    it "defaults to true" do
      is_expected.to be true
    end
  end

  describe "batch_upload?" do
    subject { described_class.batch_upload? }

    it "defaults to true" do
      is_expected.to be true
    end
  end

  describe "hide_private_items?" do
    subject { described_class.hide_private_items? }

    it "defaults to false" do
      is_expected.to be false
    end
  end
end
