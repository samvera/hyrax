require 'spec_helper'
require 'sufia/controlled_vocabulary/importer/language'

RSpec.describe Sufia::ControlledVocabulary::Importer::Language do
  before do
    allow(Rails.logger).to receive(:extend)
    allow(Sufia::ControlledVocabulary::Importer::Downloader).to receive(:fetch)
    allow(instance).to receive(:system) do
      allow($CHILD_STATUS).to receive(:success?).and_return(true)
    end
  end

  let(:instance) { described_class.new }
  let(:rdf_path) { Gem.loaded_specs['sufia'].full_gem_path + "/.internal_test_app/tmp/lexvo_2013-02-09.rdf" }
  it "imports stuff" do
    expect(Qa::Services::RDFAuthorityParser).to receive(:import_rdf).with(
      'languages',
      [rdf_path],
      format: 'rdfxml',
      predicate: RDF::Vocab::SKOS.prefLabel
    )
    instance.import
  end
end
