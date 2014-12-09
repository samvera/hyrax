require 'spec_helper'

describe Sufia::VersionListPresenter, :no_clean do
  let(:resource_version) do
    ActiveFedora::VersionsGraph::ResourceVersion.new.tap do |v|
      v.uri = 'http://example.com/version1'
      v.label = 'version1'
      v.created = '2014-12-09T02:03:18.296Z'
    end
  end

  subject { Sufia::VersionListPresenter.new([resource_version]) }

  describe "#each" do
    it "should yield version_presenters" do
      subject.each do |v|
        expect(v).to be_kind_of Sufia::VersionPresenter
        expect(v.label).to eq 'version1'
      end
    end
  end
end
