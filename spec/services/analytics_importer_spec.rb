# frozen_string_literal: true
#
require 'rails_helper'

# TODO questions
# 1. I'm assuming the only job of the Analytics subclasses is to return Openstruct queries
# 1.1 It's also their job to manage multiple batches?
# 2. Do we still need user stats? We have them now and they're used in addition to the other tables. Hmm...
# 2.1 If we keep, then the importer will need to persist those too, or have the subclasses own it..

RSpec.describe AnalyticsImporter do
  let(:start_date) { 2.days.ago }
  let(:end_date) { 1.day.ago }
  let(:importer) { described_class.new(start_date, end_date) }

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:resource1) { '12345' }
  let(:resource2) { '23456' }
  let(:resource3) { '34567' }
  let(:fileset1) { '45678' }
  let(:fileset2) { '56789' }
  let(:fileset3) { '67890' }

  context 'importing remote statistics' do
    let(:page_level_results) do
      [OpenStruct.new(date: start_date.strftime("%Y-%m-%d"), pagePath: "/concern/parent/#{resource1}/file_sets/#{fileset1}", newUsers: '10', users: '20', pageviews: '5'),
       OpenStruct.new(date: start_date.strftime("%Y-%m-%d"), pagePath: "/concern/parent/#{resource2}/file_sets/#{fileset2}", newUsers: '11', users: '21', pageviews: '6'),
       OpenStruct.new(date: start_date.strftime("%Y-%m-%d"), pagePath: "/concern/parent/#{resource3}/file_sets/#{fileset3}", newUsers: '12', users: '22', pageviews: '7'),
       OpenStruct.new(date: start_date.strftime("%Y-%m-%d"), pagePath: "/concern/generic_works/#{resource1}", newUsers: '6', users: '9', pageviews: '4'),
       OpenStruct.new(date: start_date.strftime("%Y-%m-%d"), pagePath: "/concern/generic_works/#{resource2}", newUsers: '7', users: '10', pageviews: '5'),
       OpenStruct.new(date: start_date.strftime("%Y-%m-%d"), pagePath: "/concern/generic_works/#{resource3}", newUsers: '8', users: '11', pageviews: '6')]
    end

    let(:site_level_results) do
      [OpenStruct.new(date: start_date.strftime("%Y-%m-%d"), newUsers: '10', users: '20'),
       OpenStruct.new(date: end_date.strftime("%Y-%m-%d"), newUsers: '11', users: '21')]
    end

    let(:analytics_service) do
      instance_double(Hyrax::Analytics::GoogleAnalytics,
                      page_report: page_level_results,
                      site_report: site_level_results)
    end

    before do
      allow(importer).to receive(:import_page_stats).and_return(page_level_results)
      allow(importer).to receive(:import_site_stats).and_return(site_level_results)

      allow(ActiveFedora::Base).to receive(:find).with(resource1).once.and_return(GenericWork.new(id: resource1, depositor: user1.login))
      allow(ActiveFedora::Base).to receive(:find).with(resource2).once.and_return(GenericWork.new(id: resource2, depositor: user1.login))
      allow(ActiveFedora::Base).to receive(:find).with(resource3).once.and_return(GenericWork.new(id: resource3, depositor: user2.login))
      allow(ActiveFedora::Base).to receive(:find).with(fileset1).once.and_return(FileSet.new(id: fileset1, depositor: user1.login))
      allow(ActiveFedora::Base).to receive(:find).with(fileset2).once.and_return(FileSet.new(id: fileset2, depositor: user1.login))
      allow(ActiveFedora::Base).to receive(:find).with(fileset3).once.and_return(FileSet.new(id: fileset3, depositor: user2.login))
    end

    describe '#import_page_stats' do
      # TODO: rig up a test or five for when the results have a `nextPageToken` and expect this function to be called twice
      #       This might require some stubbing of properties in the subclasses, so we'll need them built..

      context 'has existing download stats' do
        before do
          ResourceStat.create(date: start_date.strftime("%Y-%m-%d"), downloads: 12, resource_id: fileset1, user_id: user1.id)
          ResourceStat.create(date: start_date.strftime("%Y-%m-%d"), downloads: 23, resource_id: fileset2, user_id: user1.id)
          ResourceStat.create(date: start_date.strftime("%Y-%m-%d"), downloads: 56, resource_id: fileset3, user_id: user2.id)
        end

        it 'creates and updates page level cached statistics' do
          expect(ResourceStat.count).to eq(3)
          importer.import_page_stats
          expect(ResourceStat.count).to eq(6)
          page_stats = ResourceStat.all
          expect(page_stats[0]).to have_attributes(date: start_date,
                                                   resource_id: fileset1,
                                                   user_id: user1.id,
                                                   newUsers: '10',
                                                   users: '20',
                                                   downloads: '12',
                                                   pageviews: '5')
        end
      end

      context 'has no existing download statistics' do
        it 'creates page level cached statistics' do
          expect(ResourceStat.count).to eq(0)
          importer.import_page_stats
          expect(ResourceStat.count).to eq(6)
        end
      end
    end

    describe '#import_site_stats' do
      it 'requires a page_token' do
        expect(importer.import_site_stats).to raise_error(ArgumentError)
      end

      it 'creates site level cached statistics' do
        expect(ResourceStat.count).to eq(0)
        importer.import_site_stats
        expect(ResourceStat.count).to eq(1)
        site_stats = ResourceStat.all
        expect(site_stats[0]).to have_attributes(date: start_date,
                                                 newUsers: '10',
                                                 users: '20')
      end
    end
  end
end
