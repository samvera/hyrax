# frozen_string_literal: true
require 'hyrax/controlled_vocabulary/importer/language'

RSpec.describe Hyrax::ControlledVocabulary::Importer::Language do
  before do
    allow(Hyrax.logger).to receive(:extend)
    allow(Hyrax::ControlledVocabulary::Importer::Downloader).to receive(:fetch)
    allow(instance).to receive(:extract)
  end

  let(:instance) { described_class.new }
  let(:rdf_path) { Rails.root.join('tmp', 'lexvo_2013-02-09.rdf').to_s }

  it "imports stuff" do
    expect(Qa::Services::RDFAuthorityParser).to receive(:import_rdf).with(
      'languages',
      [rdf_path],
      format: 'rdfxml',
      predicate: RDF::URI('http://www.w3.org/2008/05/skos#prefLabel')
    )
    instance.import
  end
end
