# frozen_string_literal: true
RSpec.describe Hyrax::GraphExporter do
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

    context "when a Ldp::NotFound is raised" do
      let(:mock_service) { instance_double(Hydra::ContentNegotiation::CleanGraphRepository) }

      before do
        allow(service).to receive(:clean_graph_repository).and_return(mock_service)
        allow(mock_service).to receive(:find).and_raise(Ldp::NotFound)
      end
      it "raises a error that the controller catches and handles" do
        expect { subject }.to raise_error ActiveFedora::ObjectNotFoundError
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
        mapped_fragments   = subject.query(predicate: RDF.type, object: RDF::Vocab::EDM.TimeSpan)
                                    .subjects
                                    .map(&:fragment)

        expect(mapped_fragments).to contain_exactly(*resource_fragments)
      end
    end
  end
end
