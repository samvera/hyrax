# frozen_string_literal: true
RSpec.describe BatchUploadItem do
  describe ".human_readable_type" do
    subject { described_class.human_readable_type }

    it { is_expected.to eq 'Works by Batch' }
  end
end
