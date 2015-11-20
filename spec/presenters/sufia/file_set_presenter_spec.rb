require 'spec_helper'

describe Sufia::FileSetPresenter do
  let(:solr_document) { SolrDocument.new(file.to_solr) }
  let(:ability) { double "Ability" }
  let(:presenter) { described_class.new(solr_document, ability) }

  describe '#tweeter' do
    let(:file) { build(:file_set).tap { |f| f.apply_depositor_metadata(user) } }
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
end
