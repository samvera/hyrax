# frozen_string_literal: true
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

  # NOTE: This is set to true in Koppie's config.
  unless Hyrax.config.disable_wings
    describe "batch_upload?" do
      subject { described_class.batch_upload? }

      it "defaults to false" do
        is_expected.to be false
      end
    end
  end

  describe "hide_private_items?" do
    subject { described_class.hide_private_items? }

    it "defaults to false" do
      is_expected.to be false
    end
  end

  describe "hide_users_list?" do
    subject { described_class.hide_users_list? }

    it "defaults to true" do
      is_expected.to be true
    end
  end

  describe "cache_work_iiif_manifest?" do
    subject { described_class.cache_work_iiif_manifest? }

    # This was the previous behavior. At a certain point, we'll likely
    # flip the default behavior to `true`. But for now, the goal is to
    # not introduce a code change
    it "defaults to false" do
      is_expected.to be false
    end
  end
end
