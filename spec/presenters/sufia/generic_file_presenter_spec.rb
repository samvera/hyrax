require 'spec_helper'

describe Sufia::GenericFilePresenter do
  describe ".terms" do
    it "should return a list" do
      expect(described_class.terms).to eq([:resource_type, :title,
        :creator, :contributor, :description, :tag, :rights, :publisher,
        :date_created, :subject, :language, :identifier, :based_near,
        :related_url])
    end
  end

  let(:presenter) { Sufia::GenericFilePresenter.new(file) }

  describe '#tweeter' do
    let(:file) { build(:generic_file).tap { |f| f.apply_depositor_metadata(user) } }
    subject { presenter.tweeter }

    context "with a user that can be found" do
      let(:user) { create :user, twitter_handle: 'test' }
      it { is_expected.to eq '@test' }
    end

    context "with a user that doesn't have a twitter handle" do
      let(:user) { create :user, twitter_handle: '' }
      it { is_expected.to eq '@HydraSphere' }
    end

    context "with a user that can't be found" do
      let(:user) { 'sarah' }
      it { is_expected.to eq '@HydraSphere' }
    end
  end

  describe '#itemtype' do
    let(:file) { build(:generic_file, resource_type: type) }

    subject { presenter.itemtype }

    context 'when resource_type is Audio' do
      let(:type) { ['Audio'] }

      it { is_expected.to eq 'http://schema.org/AudioObject' }
    end

    context 'when resource_type is Conference Proceeding' do
      let(:type) { ['Conference Proceeding'] }

      it { is_expected.to eq 'http://schema.org/ScholarlyArticle' }
    end
  end
end
