require 'spec_helper'

describe Sufia::VersionPresenter, :no_clean do
  let(:resource_version) do
    ActiveFedora::VersionsGraph::ResourceVersion.new.tap do |v|
      v.uri = 'http://example.com/version1'
      v.label = 'version1'
      v.created = '2014-12-09T02:03:18.296Z'
    end
  end

  let(:presenter) { Sufia::VersionPresenter.new(resource_version) }

  describe "#label" do
    subject { presenter.label }
    it { is_expected.to eq 'version1' }
  end

  describe "#uri" do
    subject { presenter.uri }
    it { is_expected.to eq 'http://example.com/version1' }
  end

  describe "#created" do
    before do
      # Stub out the local timezone to (+08:00)
      t2 = Time.new(2014, 12, 8, 18, 3, 18, 8)
      allow_any_instance_of(Time).to receive(:getlocal).and_return(t2)
    end
    subject { presenter.created }
    it { is_expected.to eq "December 8th, 2014 18:03" }
  end

  describe "#current?" do
    subject { presenter.current? }
    it { is_expected.to be false }

    context "when current! is set" do
      before { presenter.current! }
      it { is_expected.to be true }
    end
  end

  describe "#committer" do
    before do
      VersionCommitter.create(version_id: resource_version.uri, committer_login: 'jill')
    end
    subject { presenter.committer }
    it { is_expected.to eq 'jill' }
  end
end
