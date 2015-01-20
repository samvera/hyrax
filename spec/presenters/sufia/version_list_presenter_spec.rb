require 'spec_helper'

describe Sufia::VersionListPresenter, :no_clean do
  let(:resource_version) do
    ActiveFedora::VersionsGraph::ResourceVersion.new.tap do |v|
      v.uri = 'http://example.com/version1'
      v.label = 'version1'
      v.created = '2014-12-09T02:03:18.296Z'
    end
  end

  let(:resource_version2) do
    ActiveFedora::VersionsGraph::ResourceVersion.new.tap do |v|
      v.uri = 'http://example.com/version2'
      v.label = 'version2'
      v.created = '2014-12-19T02:03:18.296Z'
    end
  end

  subject { Sufia::VersionListPresenter.new([resource_version, resource_version2]) }

  describe "#each" do
    it "should yield version_presenters" do
      versions_descending = []
      subject.each do |v|
        expect(v).to be_kind_of Sufia::VersionPresenter
        versions_descending.push(v.label)
      end
      expect(versions_descending).to eq ['version2', 'version1']
    end
  end
end
