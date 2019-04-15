# rubocop:disable RSpec/InstanceVariable
RSpec.describe Hyrax::Works::MigrationService, clean_repo: true do
  let(:predicate_from) { ::RDF::Vocab::DC11.description }
  let(:predicate_to) { ::RDF::Vocab::SCHEMA.description }

  describe "#migrate_predicate" do
    it "uses DC description by default" do
      @work = GenericWork.create(title: ["War and Peace"], description: ["war", "peace"])
      expect(@work.ldp_source.content).to include("http://purl.org/dc/elements/1.1/description")
    end

    it "updates to use SCHEMA description" do
      @work = GenericWork.create(title: ["War and Peace"], description: ["war", "peace"])
      described_class.migrate_predicate(predicate_from, predicate_to)
      @work.reload
      expect(@work.ldp_source.content).to include("http://schema.org/description")
      expect(@work.ldp_source.content).not_to include("http://purl.org/dc/elements/1.1/description")
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
