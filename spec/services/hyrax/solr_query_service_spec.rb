# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax::SolrQueryService do
  subject(:solr_query_service) { described_class.new(query: [initial_query]) }
  let(:initial_query) { '_query_:"{!field f=subject_ssim:Science"' }

  it do
    is_expected.to respond_to :query
    is_expected.to respond_to :solr_service
  end

  describe '#get' do
    let!(:work1) { create(:work, id: 'wk1', creator: ['Mark']) }
    let!(:work2) { create(:work, id: 'wk2', creator: ['Fred']) }
    let!(:work3) { create(:work, id: 'wk3', creator: ['Mark']) }
    subject(:solr_query_service) { described_class.new }

    before { solr_query_service.with_field_pairs(field_pairs: { creator_tesim: 'Mark' }) }

    it 'get solr document matching the query' do
      results = solr_query_service.get["response"]["docs"]
      expect(results.count).to eq 2
      expect(results.map { |doc| doc["id"] }).to match_array ['wk1', 'wk3']
    end
  end

  describe '#get_ids' do
    let!(:work1) { create(:work, id: 'wk1', creator: ['Mark']) }
    let!(:work2) { create(:work, id: 'wk2', creator: ['Fred']) }
    let!(:work3) { create(:work, id: 'wk3', creator: ['Mark']) }
    subject(:solr_query_service) { described_class.new }

    before { solr_query_service.with_field_pairs(field_pairs: { creator_tesim: 'Mark' }) }

    it 'get ids for solr document matching the query' do
      ids = solr_query_service.get_ids
      expect(ids.count).to eq 2
      expect(ids).to match_array ['wk1', 'wk3']
    end
  end

  describe '#get_objects' do
    let!(:work1) { create(:work, id: 'wk1', creator: ['Mark']) }
    let!(:work2) { create(:work, id: 'wk2', creator: ['Fred']) }
    let!(:work3) { create(:work, id: 'wk3', creator: ['Mark']) }
    subject(:solr_query_service) { described_class.new }

    before { solr_query_service.with_field_pairs(field_pairs: { creator_tesim: 'Mark' }) }

    context "when use_valkyrie is false" do
      it 'get ActiveFedora::Base objects matching the query' do
        objects = solr_query_service.get_objects(use_valkyrie: false)
        expect(objects.count).to eq 2
        expect(objects.first).to be_kind_of ActiveFedora::Base
        expect(objects.map(&:id)).to match_array ['wk1', 'wk3']
      end
    end

    context "when use_valkyrie is true" do
      it 'get Valkyrie::Resource objects matching the query' do
        objects = solr_query_service.get_objects(use_valkyrie: true)
        expect(objects.count).to eq 2
        expect(objects.first).to be_kind_of Valkyrie::Resource
        expect(objects.map(&:id)).to match_array ['wk1', 'wk3']
      end
    end
  end

  describe '#count' do
    let!(:work1) { create(:work, id: 'wk1', creator: ['Mark']) }
    let!(:work2) { create(:work, id: 'wk2', creator: ['Fred']) }
    let!(:work3) { create(:work, id: 'wk3', creator: ['Mark']) }
    subject(:solr_query_service) { described_class.new }

    before { solr_query_service.with_field_pairs(field_pairs: { creator_tesim: 'Mark' }) }

    it 'counts the number of results matching the query' do
      expect(solr_query_service.count).to eq 2
    end
  end

  describe '#build' do
    context 'when no query clauses have been constructed' do
      subject(:solr_query_service) { described_class.new }
      it "returns a valid solr query that will return 0 results" do
        expect(solr_query_service.build).to eq "id:NEVER_USE_THIS_ID"
      end
    end

    context 'when one query clause has been constructed' do
      let(:initial_query) { '_query_:"{!field f=subject_ssim:Science"' }
      it "returns the one solr query clause" do
        expect(solr_query_service.build).to eq initial_query
      end
    end

    context 'when multiple query clauses has been constructed' do
      let(:initial_query) { '_query_:"{!field f=subject_ssim:Science"' }
      before do
        solr_query_service.with_ids(ids: ['id1', 'id2'])
        solr_query_service.with_model(model: Monograph)
      end
      it "returns the concatenated solr query clauses" do
        expect(solr_query_service.build).to eq '_query_:"{!field f=subject_ssim:Science" AND ' \
                                               '{!terms f=id}id1,id2 AND ' \
                                               '_query_:"{!field f=has_model_ssim}Monograph"'
      end
    end
  end

  describe '#reset' do
    it 'resets the query to have no query clauses' do
      expect(solr_query_service.query).to be_kind_of Array
      expect(solr_query_service.query).not_to be_empty
      expect(solr_query_service.reset.query).to eq []
    end
  end

  describe '#with_ids' do
    it "generates and appends a query clause" do
      expect(solr_query_service.with_ids(ids: ["an123id", "an456id", "an789id"]).query)
        .to match_array [initial_query, '{!terms f=id}an123id,an456id,an789id']
    end
  end

  describe "#with_model" do
    it "generates and appends a query clause" do
      expect(solr_query_service.with_model(model: ::Collection).query)
        .to match_array [initial_query, '_query_:"{!field f=has_model_ssim}Collection"']
    end
  end

  describe "#with_generic_type" do
    it "generates with type Work if no type is passed in and appends a query clause" do
      expect(solr_query_service.with_generic_type.query)
        .to match_array [initial_query, '(_query_:"{!field f=generic_type_si}Work" OR _query_:"{!field f=generic_type_sim}Work")']
    end

    it "generates and appends a query clause" do
      expect(solr_query_service.with_generic_type(generic_type: 'Collection').query)
        .to match_array [initial_query, '(_query_:"{!field f=generic_type_si}Collection" OR _query_:"{!field f=generic_type_sim}Collection")']
    end
  end

  describe "#with_field_pairs" do
    let(:field_pairs) do
      {
        title_tesim: 'Learn Science',
        depositor_ssim: 'a_user@example.com'
      }
    end
    it "generates and appends a query clause using default join_with for multiple pairs" do
      expect(solr_query_service.with_field_pairs(field_pairs: field_pairs).query)
        .to match_array [initial_query, '(_query_:"{!field f=title_tesim}Learn Science" AND _query_:"{!field f=depositor_ssim}a_user@example.com")']
    end

    it "generates and appends a query clause using passed in join_with for multiple pairs" do
      expect(solr_query_service.with_field_pairs(field_pairs: field_pairs, join_with: ' OR ').query)
        .to match_array [initial_query, '(_query_:"{!field f=title_tesim}Learn Science" OR _query_:"{!field f=depositor_ssim}a_user@example.com")']
    end
  end
end
