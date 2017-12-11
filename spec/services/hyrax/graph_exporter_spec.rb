RSpec.describe Hyrax::GraphExporter do
  let(:work) { create_for_repository(:work_with_one_file, visibility: 'open') }
  let(:document) { double(id: work.id.to_s) }
  let(:request) { double(host: 'localhost') }
  let(:service) { described_class.new(document, request) }

  describe "fetch" do
    subject { service.fetch }

    let(:ttl) { subject.dump(:ntriples) }

    it "transforms to rdf" do
      expect(ttl).to match %r{<http://purl\.org/dc/terms/title> "Test title"}
    end
  end
end
