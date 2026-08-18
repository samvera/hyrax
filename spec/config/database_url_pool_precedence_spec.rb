# frozen_string_literal: true

require 'rails_helper'

# DATABASE_URL and url's own ?pool= silently win over database.yml's
# separate pool key for the same environment
RSpec.describe 'DATABASE_URL vs database.yml pool precedence' do
  before do
    allow(ENV).to receive(:[]).and_call_original
  end

  let(:env_name) { Rails.env.to_s }
  let(:config_hash) do
    { env_name => { 'adapter' => 'definitely-not-a-real-adapter', 'database' => 'db', 'pool' => 13 } }
  end

  let(:resolved_pool_size) do
    configurations = ActiveRecord::DatabaseConfigurations.new(config_hash)
    db_config = configurations.configs_for(env_name: env_name, name: 'primary')
    db_config.pool
  end

  context 'when DATABASE_URL is not set' do
    before do
      allow(ENV).to receive(:[]).with('DATABASE_URL').and_return(nil)
    end

    it 'uses pool from database.yml as authoritative source' do
      expect(resolved_pool_size).to eq(13)
    end
  end

  context 'when DATABASE_URL includes ?pool=' do
    before do
      allow(ENV).to receive(:[]).with('DATABASE_URL').and_return('definitely-not-a-real-adapter://host/db?pool=99')
    end

    it 'uses pool from DATABASE_URL as authoritative source' do
      expect(resolved_pool_size).to eq(99)
    end
  end

  context 'when DATABASE_URL is set and does not include ?pool=' do
    before do
      allow(ENV).to receive(:[]).with('DATABASE_URL').and_return('definitely-not-a-real-adapter://host/db')
    end

    it 'uses pool from database.yml as authoritative source' do
      expect(resolved_pool_size).to eq(13)
    end
  end

  context 'when url is set in database.yaml' do
    context 'with pool set in url' do
      let(:config_hash) do
        { env_name => { 'adapter' => 'definitely-not-a-real-adapter', 'database' => 'db', 'pool' => 13, 'url' => 'a-different-adapter://host/pg?pool=99' } }
      end

      it 'uses pool from url' do
        expect(resolved_pool_size).to eq(99)
      end
    end
    context 'with no pool set in url' do
      let(:config_hash) do
        { env_name => { 'adapter' => 'definitely-not-a-real-adapter', 'database' => 'db', 'pool' => 13, 'url' => 'a-different-adapter://host/pg' } }
      end

      it 'uses pool from pool key' do
        expect(resolved_pool_size).to eq(13)
      end
    end
  end
end
