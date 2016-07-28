require 'spec_helper'

RSpec.describe CurationConcerns::GraphExporter do
  let(:work) { create(:work_with_one_file, visibility: 'open') }
  let(:document) { double(id: work.id) }
  let(:request) { double(host: 'localhost') }
  let(:service) { described_class.new(document, request) }

  describe "fetch" do
    subject { service.fetch }
    let(:ttl) { subject.dump(:ntriples) }
    it "transforms suburis to hashcodes" do
      expect(ttl).to match %r{<http://localhost/concern/generic_works/#{work.id}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://projecthydra.org/works/models#Work>}
      expect(ttl).to match %r{<http://purl\.org/dc/terms/title> "Test title"}
      expect(ttl).to match %r{<http://www\.w3\.org/ns/auth/acl#accessControl> <http://localhost/catalog/}

      query = subject.query([RDF::URI("http://localhost/concern/generic_works/#{work.id}"),
                             RDF::URI("http://www.iana.org/assignments/relation/first"),
                             nil])
      proxy = query.to_a.first.object

      expect(proxy.to_s).to match %r{http://localhost/concern/generic_works/#{work.id}/list_source#g\d+}

      # It includes the list nodes on the graph
      expect(subject.query([proxy, nil, nil]).count).to eq 2
    end
  end
end
