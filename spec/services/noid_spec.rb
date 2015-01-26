require 'spec_helper'

describe Sufia::Noid do
  describe "#treeify" do
    subject { Sufia::Noid.treeify(id) }
    let(:id) { 'abc123def45' }
    it { is_expected.to eq 'ab/c1/23/de/abc123def45' }
  end
end
