# frozen_string_literal: true
RSpec.describe Hyrax::DeepIndexingService do
  subject(:service) { described_class.new(work) }
  let(:work) { FactoryBot.build(:work) }

  before do
    newberg = <<RDFXML.strip_heredoc
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
          <rdf:RDF xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:gn="http://www.geonames.org/ontology#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">
          <gn:Feature rdf:about="http://sws.geonames.org/5037649/">
          <rdfs:label>an RDFS Label</gn:name>
          <gn:name>Newberg</gn:name>
          </gn:Feature>
          </rdf:RDF>
RDFXML

    stub_request(:get, "http://sws.geonames.org/5037649/")
      .to_return(status: 200, body: newberg,
                 headers: { 'Content-Type' => 'application/rdf+xml;charset=UTF-8' })
  end

  describe '#add_assertions' do
    it "adds the rdf_label from the authoritative source" do
      work.based_near_attributes = [{ id: 'http://sws.geonames.org/5037649/' }]

      expect { service.add_assertions(nil) }
        .to change { work.based_near.map(&:rdf_label).flatten }
        .to contain_exactly(["Newberg"])
    end
  end
end
