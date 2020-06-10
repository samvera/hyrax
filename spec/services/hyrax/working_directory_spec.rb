# frozen_string_literal: true
RSpec.describe Hyrax::WorkingDirectory do
  let(:path1) { described_class.send(:full_filename, 'abcdefghijklmnop1', 'foo.tif') }
  let(:path2) { described_class.send(:full_filename, 'abcdefghijklmnop2', 'foo.tif') }

  describe "#full_filename" do
    it "generates unique filenames for different files" do
      expect(path1).not_to eq(path2)
      expect(path1).to match(/\/tmp\/uploads\/ab\/cd\/ef\/gh\/abcdefghijklmnop1\/foo.tif$/)
      expect(path2).to match(/\/tmp\/uploads\/ab\/cd\/ef\/gh\/abcdefghijklmnop2\/foo.tif$/)
    end
  end
end
