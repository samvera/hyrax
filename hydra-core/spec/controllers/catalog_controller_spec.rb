require 'spec_helper'

describe CatalogController do

  before do
    session[:user]='bob'
  end

  it "uses the CatalogController" do
    expect(controller).to be_an_instance_of CatalogController
  end

  describe "configuration" do
    let(:config) { CatalogController.blacklight_config }
    describe "search_builder_class" do
      subject {config.search_builder_class }
      it { is_expected.to eq ::SearchBuilder }
    end
  end

  describe "index" do
    describe "access controls" do
      before(:all) do
        fq = "read_access_group_ssim:public OR edit_access_group_ssim:public OR discover_access_group_ssim:public"
        solr_opts = { fq: fq }
        response = ActiveFedora::SolrService.instance.conn.get('select', params: solr_opts)
        @public_only_results = Blacklight::Solr::Response.new(response, solr_opts)
      end

      it "should only return public documents if role does not have permissions" do
        allow(controller).to receive(:current_user).and_return(nil)
        get :index
        expect(assigns(:document_list).count).to eq @public_only_results.docs.count
      end

      it "should return documents if the group names need to be escaped" do
        allow(RoleMapper).to receive(:roles).and_return(["abc/123","cde/567"])
        get :index
        expect(assigns(:document_list).count).to eq @public_only_results.docs.count
      end
    end
  end

  describe "content negotiation" do
    describe "show" do
      before do
        allow(controller).to receive(:enforce_show_permissions)
      end
      context "with no asset" do
        it "returns a not found response code" do
          get 'show', params: { id: "test", format: :nt }

          expect(response).to be_not_found
        end
      end
      context "with an asset" do
        let(:type) { RDF::URI("http://example.org/example") }
        let(:related_uri) { related.rdf_subject }
        let(:asset) do
          ActiveFedora::Base.create do |g|
            g.resource << [g.rdf_subject, RDF::Vocab::DC.title, "Test Title"]
            g.resource << [g.rdf_subject, RDF.type, type]
            g.resource << [g.rdf_subject, RDF::Vocab::DC.isReferencedBy, related_uri]
          end
        end
        let(:related) do
          ActiveFedora::Base.create
        end
        it "is able to negotiate jsonld" do
          get 'show', params: { id: asset.id, format: :jsonld }

          expect(response).to be_success
          expect(response.headers['Content-Type']).to include("application/ld+json")
          graph = RDF::Reader.for(:jsonld).new(response.body)
          expect(graph.statements.to_a.length).to eq 3
        end

        it "is able to negotiate ttl" do
          get 'show', params: { id: asset.id, format: :ttl }
          
          expect(response).to be_success
          graph = RDF::Reader.for(:ttl).new(response.body)
          expect(graph.statements.to_a.length).to eq 3
        end

        it "returns an n-triples graph with just the content put in" do
          get 'show', params: { id: asset.id, format: :nt }

          graph = RDF::Reader.for(:ntriples).new(response.body)
          statements = graph.statements.to_a
          expect(statements.length).to eq 3
          expect(statements.first.subject).to eq asset.rdf_subject
        end

        context "with a configured subject converter" do
          before do
            Hydra.config.id_to_resource_uri = lambda { |id, _| "http://hydra.box/catalog/#{id}" }
            get 'show', params: { id: asset.id, format: :nt }
          end

          it "converts the subject using the specified converter" do
            graph = RDF::Graph.new << RDF::Reader.for(:ntriples).new(response.body)
            title_statement = graph.query([nil, RDF::Vocab::DC.title, nil]).first
            related_statement = graph.query([nil, RDF::Vocab::DC.isReferencedBy, nil]).first
            expect(title_statement.subject).to eq RDF::URI("http://hydra.box/catalog/#{asset.id}")
            expect(related_statement.object).to eq RDF::URI("http://hydra.box/catalog/#{related.id}")
          end
        end
      end
    end
  end

  describe "filters" do
    describe "show" do
      it "triggers enforce_show_permissions" do
        allow(controller).to receive(:current_user).and_return(nil)
        expect(controller).to receive(:enforce_show_permissions)
        get :show, params: { id: 'test:3' }
      end
    end
  end

  describe "enforce_show_permissions" do
    let(:email_edit_access) { "edit_access@example.com" }
    let(:email_read_access) { "read_access@example.com" }
    let(:future_date) { 2.days.from_now.strftime("%Y-%m-%dT%H:%M:%SZ") }

    let(:embargoed_object) {
      doc = SolrDocument.new(id: '123',
              "edit_access_person_ssim" => [email_edit_access],
              "read_access_person_ssim" => [email_read_access],
              "embargo_release_date_dtsi" => future_date)
      solr = Blacklight.default_index.connection
      solr.add(doc)
      solr.commit
      doc
    }

    before do
      controller.params = { id: embargoed_object.id }
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'a user with edit permissions' do
      let(:user) { User.new email: email_edit_access }

      it 'allows the user to view an embargoed object' do
        expect {
          controller.send(:enforce_show_permissions, {})
        }.not_to raise_error
      end
    end

    context 'a user without edit permissions' do
      let(:user) { User.new email: email_read_access }

      it 'denies access to the embargoed object' do
        expect {
          controller.send(:enforce_show_permissions, {})
        }.to raise_error Hydra::AccessDenied, "This item is under embargo.  You do not have sufficient access privileges to read this document."
      end
    end
  end

end
