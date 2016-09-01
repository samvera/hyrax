require 'spec_helper'

RSpec.describe CurationConcerns::AdminSetService do
  let(:controller) { ::CatalogController.new }

  let(:context) do
    double(current_ability: Ability.new(user),
           repository: controller.repository,
           blacklight_config: controller.blacklight_config)
  end

  let(:service) { described_class.new(context) }
  let(:user) { create(:user) }

  describe "#select_options" do
    context "with default (read) access" do
      subject { service.select_options }
      let(:solr_doc1) { instance_double(SolrDocument, id: '123', to_s: 'foo') }
      let(:solr_doc2) { instance_double(SolrDocument, id: '234', to_s: 'bar') }
      let(:solr_doc3) { instance_double(SolrDocument, id: '345', to_s: 'baz') }

      before do
        allow(service).to receive(:search_results)
          .with(:read)
          .and_return([solr_doc1, solr_doc2, solr_doc3])
      end

      it { is_expected.to eq [['foo', '123'],
                              ['bar', '234'],
                              ['baz', '345']] }
    end

    context "with explicit edit access" do
      subject { service.select_options(:edit) }
      let(:solr_doc) { instance_double(SolrDocument, id: '123', to_s: 'baz') }

      before do
        allow(service).to receive(:search_results).with(:edit).and_return([solr_doc])
      end

      it { is_expected.to eq [['baz', '123']] }
    end
  end

  describe "#search_results" do
    subject { service.search_results(access) }
    let!(:as1) { create(:admin_set, :public, title: ['foo']) }
    let!(:as2) { create(:admin_set, :public, title: ['bar']) }
    let!(:as3) { create(:admin_set, edit_users: [user.user_key], title: ['baz']) }
    before do
      create(:collection, :public) # this should never be returned.
    end

    context "with read access" do
      let(:access) { :read }
      it "returns three admin sets" do
        expect(subject.map(&:id)).to match_array [as1.id, as2.id, as3.id]
      end
    end

    context "with edit access" do
      let(:access) { :edit }
      it "returns one admin set" do
        expect(subject.map(&:id)).to match_array [as3.id]
      end
    end
  end
end
