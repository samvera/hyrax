# frozen_string_literal: true
# rubocop:disable RSpec/InstanceVariable
RSpec.describe Hyrax::Works::MigrationService, :active_fedora, clean_repo: true do
  let(:predicate_from) { ::RDF::Vocab::DC11.description }
  let(:predicate_to) { ::RDF::Vocab::SCHEMA.description }
  let(:predicate_from2) { ::RDF::Vocab::DC.rights }
  let(:predicate_to2) { ::RDF::Vocab::DC.license }

  describe "#migrate_predicate" do
    it "uses DC description and DC license by default" do
      @work = GenericWork.create(title: ["War and Peace"], description: ["war", "peace"],
                                 license: ["the_license_string"])
      expect(@work.ldp_source.content).to include("http://purl.org/dc/elements/1.1/description")
      expect(@work.ldp_source.content).to include(predicate_to2.to_s)
    end

    it "updates to use SCHEMA description" do
      @work = GenericWork.create(title: ["War and Peace"], description: ["war", "peace"],
                                 license: ["the_license_string"])
      described_class.migrate_predicate(predicate_from, predicate_to)
      described_class.migrate_predicate(predicate_from2, predicate_to2)
      @work.reload
      expect(@work.ldp_source.content).to include("http://schema.org/description")
      expect(@work.ldp_source.content).not_to include("http://purl.org/dc/elements/1.1/description")
      expect(@work.ldp_source.content).to include(predicate_to2.to_s)
      expect(@work.ldp_source.content).not_to include(predicate_from2.to_s)
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
