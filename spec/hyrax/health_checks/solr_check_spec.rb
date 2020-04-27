# frozen_string_literal: true

require 'hyrax/health_checks/solr_check'

RSpec.describe Hyrax::HealthChecks::SolrCheck do
  subject(:check) { described_class.new }

  it 'connects to solr' do
    expect { check.check }
      .not_to change { check.failure_occurred }
  end

  context 'with a broken solr service' do
    subject(:check) { described_class.new(service: solr_service) }
    let(:solr_service) { double(Hyrax::SolrService) }

    before { allow(solr_service).to receive(:ping).and_raise('oh no!') }

    it 'marks a failure' do
      expect { check.check }
        .to change { check.failure_occurred }
        .to true
    end
  end
end
