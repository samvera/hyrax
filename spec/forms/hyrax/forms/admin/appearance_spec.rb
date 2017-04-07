require 'spec_helper'

RSpec.describe Hyrax::Forms::Admin::Appearance do
  let(:form) { described_class.new({}) }

  describe "update!" do
    let(:block) { instance_double(ContentBlock) }

    before do
      allow(ContentBlock).to receive(:find_or_create_by).and_return(block)
    end

    it "calls update block 5 times" do
      expect(block).to receive(:update!).exactly(5).times
      form.update!
    end
  end
end
