# frozen_string_literal: true
#
require 'rails_helper'

RSpec.describe Hyrax::AnalyticsImporter do
  let(:start_date) { 2.days.ago.beginning_of_day }
  let(:importer) { described_class.new(start_date) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:resource1) { create(:work_with_one_file, user: user1) }
  let(:resource2) { create(:work_with_one_file, user: user1) }
  let(:resource3) { create(:work_with_one_file, user: user2) }

  let(:page_level_results) do
    { next_page_token: '', rows:
      [OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/parent/#{resource1.id}/file_sets/#{resource1.file_sets.first.id}", visitors: '10', sessions: '20', pageviews: '5'),
       OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/parent/#{resource2.id}/file_sets/#{resource2.file_sets.first.id}", visitors: '11', sessions: '21', pageviews: '6'),
       OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/parent/#{resource3.id}/file_sets/#{resource3.file_sets.first.id}", visitors: '12', sessions: '22', pageviews: '7'),
       OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/generic_works/#{resource1.id}", visitors: '6', sessions: '9', pageviews: '4'),
       OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/generic_works/#{resource2.id}", visitors: '7', sessions: '10', pageviews: '5'),
       OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/generic_works/#{resource3.id}", visitors: '8', sessions: '11', pageviews: '6')] }
  end

  let(:site_level_results) do
    { next_page_token: '', rows:
      [OpenStruct.new(date: start_date.strftime("%Y%m%d"), visitors: '10', sessions: '20')] }
  end

  let(:analytics_service) do
    class_double(Hyrax::Analytics::GoogleAnalytics)
  end

  before do
    allow(importer).to receive(:analytics_service).and_return(analytics_service)
  end

  describe '#import_page_stats' do
    context 'handles pagination of result sets' do
      let(:page_level_results_with_next_token) do
        { next_page_token: '10000', rows:
          [OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/parent/#{resource1.id}/file_sets/#{resource1.file_sets.first.id}", visitors: '10', sessions: '20', pageviews: '5'),
           OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/parent/#{resource2.id}/file_sets/#{resource2.file_sets.first.id}", visitors: '11', sessions: '21', pageviews: '6'),
           OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/parent/#{resource3.id}/file_sets/#{resource3.file_sets.first.id}", visitors: '12', sessions: '22', pageviews: '7'),
           OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/generic_works/#{resource1.id}", visitors: '6', sessions: '9', pageviews: '4'),
           OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/generic_works/#{resource2.id}", visitors: '7', sessions: '10', pageviews: '5'),
           OpenStruct.new(date: start_date.strftime("%Y%m%d"), pagePath: "/concern/generic_works/#{resource3.id}", visitors: '8', sessions: '11', pageviews: '6')] }
      end

      before do
        allow(analytics_service).to receive(:page_report).with(start_date, '10000').and_return(page_level_results)
        allow(analytics_service).to receive(:page_report).with(start_date, '0').and_return(page_level_results_with_next_token)
      end

      it 'requests the next set of results from the analytics service' do
        expect(analytics_service).to receive(:page_report).twice
        importer.import_page_stats
      end
    end

    context 'has existing download stats' do
      before do
        allow(analytics_service).to receive(:page_report).and_return(page_level_results)
        ResourceStat.create(date: start_date.strftime("%Y%m%d"), downloads: 12, resource_id: resource1.file_sets.first.id, user_id: user1.id)
        ResourceStat.create(date: start_date.strftime("%Y%m%d"), downloads: 23, resource_id: resource2.file_sets.first.id, user_id: user1.id)
        ResourceStat.create(date: start_date.strftime("%Y%m%d"), downloads: 56, resource_id: resource3.file_sets.first.id, user_id: user2.id)
      end

      it 'creates and updates page level cached statistics' do
        expect(ResourceStat.count).to eq(3)
        importer.import_page_stats
        expect(ResourceStat.count).to eq(6)
        page_stats = ResourceStat.all
        expect(page_stats[0]).to have_attributes(date: start_date, resource_id: resource1.file_sets.first.id,
                                                 user_id: user1.id, visitors: 10,
                                                 sessions: 20, downloads: 12,
                                                 pageviews: 5)
      end
    end

    context 'has no existing download statistics' do
      before do
        allow(analytics_service).to receive(:page_report).and_return(page_level_results)
      end
      it 'creates page level cached statistics' do
        expect(ResourceStat.count).to eq(0)
        importer.import_page_stats
        expect(ResourceStat.count).to eq(6)
      end
    end
  end

  describe '#import_site_stats' do
    before do
        allow(analytics_service).to receive(:site_report).and_return(site_level_results)
    end
    it 'creates site level cached statistics', :clean_repo do
      expect(ResourceStat.count).to eq(0)
      importer.import_site_stats
      expect(ResourceStat.count).to eq(1)
      site_stats = ResourceStat.all
      expect(site_stats[0]).to have_attributes(date: start_date,
                                               visitors: 10,
                                               sessions: 20)
    end
  end
end
