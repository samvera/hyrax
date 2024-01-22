# frozen_string_literal: true

# NOTE: This service focuses solely on interacting with ActiveFedora methods and connections.
RSpec.describe Hyrax::GraphExporter, :active_fedora do
  subject(:service) { described_class.new(document, hostname: 'localhost') }
  let(:work) { FactoryBot.create(:work_with_one_file, visibility: 'open') }
  let(:document) { double(id: work.id) }

  describe "fetch" do
    it "transforms suburis to hashcodes" do
      graph = service.fetch
      expect(graph.dump(:ntriples)).to match %r{<http://localhost/concern/generic_works/#{work.id}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://projecthydra.org/works/models#Work>}
      expect(graph.dump(:ntriples)).to match %r{<http://purl\.org/dc/terms/title> "Test title"}
      expect(graph.dump(:ntriples)).to match %r{<http://www\.w3\.org/ns/auth/acl#accessControl> <http://localhost/catalog/}

      proxy = graph.query([RDF::URI("http://localhost/concern/generic_works/#{work.id}"),
                           RDF::URI("http://www.iana.org/assignments/relation/first"),
                           nil])
                   .first_object
      expect(proxy).to match %r{http://localhost/concern/generic_works/#{work.id}/list_source#g\d+}

      # It includes the list nodes on the graph
      expect(graph.query([proxy, nil, nil]).count).to eq 2
    end

    context "when the resource doesn't exist" do
      let(:document) { double(id: 'a_missing_id') }

      it "raises a error that the controller catches and handles" do
        expect { service.fetch }.to raise_error ActiveFedora::ObjectNotFoundError
      end
    end

    context 'with a nested work' do
      let(:work) do
        NamespacedWorks::NestedWork
          .create(title: ['Comet in Moominland'],
                  created_attributes: [{ start: DateTime.now.utc - 1, finish: DateTime.now.utc },
                                       { start: DateTime.now.utc - 2, finish: DateTime.now.utc }])
      end

      it 'includes each nested resources once' do
        resource_fragments = work.created.map { |ts| ts.rdf_subject.fragment }
        time_spans = service.fetch.query({ predicate: RDF.type, object: RDF::Vocab::EDM.TimeSpan }).subjects

        expect(time_spans.map(&:fragment)).to contain_exactly(*resource_fragments)
      end
    end
  end
end
