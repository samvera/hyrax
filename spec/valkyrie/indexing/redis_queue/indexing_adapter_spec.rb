# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/indexing/redis_queue/indexing_adapter'

RSpec.describe Valkyrie::Indexing::RedisQueue::IndexingAdapter do
  let(:connection) { instance_double(Redis) }
  let(:index_queue_name) { 'toindex' }
  let(:delete_queue_name) { 'todelete' }
  let(:adapter) { described_class.new(connection: connection, index_queue_name: index_queue_name, delete_queue_name: delete_queue_name) }
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_resource) }
  let(:resources) { [resource] }

  before do
    Timecop.freeze(Time.current)
  end

  after do
    Timecop.return
  end

  describe '#initialize' do
    it 'sets the connection, index_queue_name, and delete_queue_name' do
      expect(adapter.connection).to eq(connection)
      expect(adapter.index_queue_name).to eq(index_queue_name)
      expect(adapter.delete_queue_name).to eq(delete_queue_name)
    end
  end

  describe '#save' do
    it 'persists the resource to the index queue' do
      expect(connection).to receive(:zadd).with(index_queue_name, Time.current.to_i, resource.id.to_s)
      adapter.save(resource: resource)
    end
  end

  describe '#save_all' do
    it 'persists multiple resources to the index queue' do
      resources.map do |r|
        expect(connection).to receive(:zadd).with(index_queue_name, Time.current.to_i, r.id.to_s)
      end
      adapter.save_all(resources: resources)
    end
  end

  describe '#delete' do
    it 'adds the resource ID to the delete queue' do
      expect(connection).to receive(:zadd).with(delete_queue_name, Time.current.to_i, resource.id.to_s)
      adapter.delete(resource: resource)
    end
  end

  describe '#wipe!' do
    it 'deletes the index and delete queues' do
      expect(connection).to receive(:del).with(index_queue_name)
      expect(connection).to receive(:del).with("#{index_queue_name}-error")
      expect(connection).to receive(:del).with(delete_queue_name)
      expect(connection).to receive(:del).with("#{delete_queue_name}-error")
      adapter.wipe!
    end
  end

  describe '#reset!' do
    it 'resets the connection to the default connection' do
      default_connection = instance_double(Redis)
      allow(Hyrax.config).to receive(:redis_connection).and_return(default_connection)
      adapter.reset!
      expect(adapter.connection).to eq(default_connection)
    end
  end

  describe '#index_queue' do
    let(:set) { [resource.id.to_s] }
    let(:solr_indexing_adapter) { instance_double(Valkyrie::Indexing::Solr::IndexingAdapter) }
    let(:solr_connection) { instance_double(RSolr::Client) }

    before do
      allow(connection).to receive(:zpopmin).with(index_queue_name, 200).and_return(set.map { |id| [id, Time.current.to_i] })
      allow(Hyrax.query_service).to receive(:find_by).with(id: resource.id.to_s).and_return(resource)
      allow(Valkyrie::IndexingAdapter).to receive(:find).with(:solr_index).and_return(solr_indexing_adapter)
      allow(solr_indexing_adapter).to receive(:save_all)
      allow(solr_indexing_adapter).to receive(:connection).and_return(solr_connection)
      allow(solr_connection).to receive(:commit)
    end

    it 'indexes the resources' do
      expect(solr_indexing_adapter).to receive(:save_all).with(resources: resources)
      adapter.index_queue
    end

    context 'when an error occurs' do
      before do
        allow(solr_indexing_adapter).to receive(:save_all).and_raise(StandardError)
      end

      it 'requeues the items' do
        set.each do |r|
          expect(connection).to receive(:zadd).with("#{index_queue_name}-error", Time.current.to_i, r)
        end
        expect { adapter.index_queue }.to raise_error(StandardError)
      end
    end
  end

  describe '#delete_queue' do
    let(:set) { [resource.id.to_s] }
    let(:solr_indexing_adapter) { instance_double(Valkyrie::Indexing::Solr::IndexingAdapter) }
    let(:solr_connection) { instance_double(RSolr::Client) }

    before do
      allow(connection).to receive(:zpopmin).with(delete_queue_name, 200).and_return(set.map { |id| [id, Time.current.to_i] })
      allow(Valkyrie::IndexingAdapter).to receive(:find).with(:solr_index).and_return(solr_indexing_adapter)
      allow(solr_indexing_adapter).to receive(:connection).and_return(solr_connection)
      allow(solr_connection).to receive(:delete_by_id)
      allow(solr_connection).to receive(:commit)
    end

    it 'deletes the resources from Solr' do
      set.each do |id|
        expect(solr_connection).to receive(:delete_by_id).with(id.to_s, { softCommit: true })
      end
      expect(solr_connection).to receive(:commit)
      adapter.delete_queue
    end

    context 'when an error occurs' do
      before do
        allow(solr_connection).to receive(:delete_by_id).and_raise(StandardError)
      end

      it 'requeues the items' do
        set.each do |r|
          expect(connection).to receive(:zadd).with("#{delete_queue_name}-error", Time.current.to_i, r)
        end
        expect { adapter.delete_queue }.to raise_error(StandardError)
      end
    end
  end
end
