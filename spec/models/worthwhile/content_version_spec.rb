require 'spec_helper'

module Worthwhile
  describe ContentVersion do
    let(:content) { double }
    let(:created_on) { Time.now }
    let(:version_id) { 'content.1'}
    let(:committer_name) { 'darryl' }
    let(:raw_version) { double(dsCreateDate: created_on, versionID: version_id) }
    subject { described_class.new(content, raw_version) }

    before do
      expect(content).to receive(:version_committer).with(raw_version).and_return(committer_name)
    end
    its(:created_on) { should eq(created_on) }
    its(:committer_name) { should eq(committer_name) }
    its(:version_id) { should eq version_id }
    its(:formatted_created_on) { should eq created_on.localtime.to_formatted_s(:long_ordinal)}
  end
  describe ContentVersion::Null do
    subject { described_class.new(double)}
    its(:created_on) { should eq 'unknown'}
    its(:committer_name) { should eq 'unknown'}
    its(:version_id) { should eq 'unknown'}
    its(:formatted_created_on) { should eq 'unknown'}
  end
end
