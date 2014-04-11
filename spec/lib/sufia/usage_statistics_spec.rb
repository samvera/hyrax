require 'spec_helper'

describe Sufia::UsageStatistics do
  before do
    token = OAuth2::AccessToken.new(nil, nil)
    allow(subject).to receive(:token).and_return(token)
  end

  it 'responds to :config' do
    expect(subject).to respond_to(:config)
  end

  it 'reads its config from a yaml file' do
    expect(subject.config.keys.sort).to eql ['app_name', 'app_version', 'client_email', 'privkey_path', 'privkey_secret']
  end

  it 'responds to :user' do
    expect(subject).to respond_to(:user)
  end

  it 'instantiates a user' do
    expect(subject.user).to be_a(Legato::User)
  end

  it 'responds to :profile' do
    expect(subject).to respond_to(:profile)
  end

  describe 'querying' do
    before do
      profile = Legato::Management::Profile.new({"id" => 12345, "name" => "Profile 1", "accountId" => "12345", "webPropertyId" => "UA-12345-2", "timezone" => "America/Chicago"}, subject.user)
      allow(subject).to receive(:profile).and_return(profile)
    end

    let(:query) { Sufia::UsageStatistics.profile.pageview }

    it 'returns a query object' do
      expect(query).to be_a(Legato::Query)
    end

    describe 'results' do
      before(:all) do
        @system_timezone = ENV['TZ']
        ENV['TZ'] = 'UTC'
      end

      after(:all) do
        ENV['TZ'] = @system_timezone
      end

      # Mock and stub Google Analytics results
      before do
        @mock_query = double('query')
        allow(@mock_query).to receive(:collection).and_return([
            OpenStruct.new(date: '2014-01-01', pageviews: 4),
            OpenStruct.new(date: '2014-01-02', pageviews: 8),
            OpenStruct.new(date: '2014-01-03', pageviews: 6),
            OpenStruct.new(date: '2014-01-04', pageviews: 10),
            OpenStruct.new(date: '2014-01-05', pageviews: 2)])
        allow(@mock_query).to receive(:map).and_return(@mock_query.collection.map(&:marshal_dump))
        allow(Sufia::UsageStatistics.profile).to receive(:pageview).and_return(@mock_query)
      end

      let(:results) { @mock_query }

      it 'converts results to json' do
        expect(subject.as_flot_json(results)).to eql('[[1388534400000,4],[1388620800000,8],[1388707200000,6],[1388793600000,10],[1388880000000,2]]')
      end

      it 'calculates total page views' do
        expect(subject.total_pageviews(results)).to eql(30)
      end
    end
  end
end
