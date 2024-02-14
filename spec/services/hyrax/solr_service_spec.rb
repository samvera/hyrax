# frozen_string_literal: true
RSpec.describe Hyrax::SolrService do
  let(:mock_conn) { instance_double(RSolr::Client) }
  let(:valkyrie_index) { double("valkyrie_index", connection: mock_conn) }
  let(:use_valkyrie) { Hyrax.config.query_index_from_valkyrie }

  before { allow(Hyrax).to receive(:index_adapter).and_return(valkyrie_index) }

  describe '.select_path' do
    it 'raises NotImplementedError' do
      expect { described_class.select_path }.to raise_error NotImplementedError
    end
  end

  describe "#get" do
    it "calls solr" do
      stub_result = double("Result")
      params = { q: 'querytext', qt: 'standard' }
      expect(mock_conn).to receive(:get).with('select', params: params).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.get('querytext')).to eq stub_result
    end

    it "uses args as params" do
      stub_result = double("Result")
      params = { fq: ["id:\"1234\""], q: 'querytext', qt: 'standard' }
      expect(mock_conn).to receive(:get).with('select', params: params).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.get('querytext', fq: ["id:\"1234\""])).to eq stub_result
    end
  end

  describe '#ping' do
    subject(:service) { described_class.new(use_valkyrie: false) }

    before do
      expect(mock_conn).to receive(:get).with('admin/ping').and_return('status' => 'OK')
    end

    it 'gives true when the connection is working' do
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(service.ping).to be true
    end

    context 'with valkyrie index configuration' do
      subject(:service) { described_class.new(use_valkyrie: true) }

      it 'gives true when the connection is working' do
        expect(service.ping).to be true
      end
    end
  end

  describe "#post" do
    it "calls solr" do
      stub_result = double("Result")
      data = { q: 'querytext', qt: 'standard' }
      expect(mock_conn).to receive(:post).with('select', data: data).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.post('querytext')).to eq stub_result
    end

    it "uses args as data" do
      stub_result = double("Result")
      data = { fq: ["id:\"1234\""], q: 'querytext', qt: 'standard' }
      expect(mock_conn).to receive(:post).with('select', data: data).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.post('querytext', fq: ["id:\"1234\""])).to eq stub_result
    end

    context "when use_valkyrie: true" do
      subject(:service) { described_class.new(use_valkyrie: true) }

      it "uses valkyrie solr based on config query_index_from_valkyrie" do
        stub_result = double("Valkyrie Result")

        expect(mock_conn).to receive(:post).with('select', data: { q: 'querytext', qt: 'standard' }).and_return(stub_result)

        expect(service.post('querytext')).to eq stub_result
      end
    end
  end

  describe "#query" do
    let(:doc) { { 'id' => 'x' } }
    let(:docs) { [doc] }
    let(:stub_result) { { 'response' => { 'docs' => docs } } }

    before do
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
    end

    it "defaults to HTTP POST method" do
      data = { rows: 2, q: 'querytext', qt: 'standard' }
      expect(mock_conn).to receive(:post).with('select', data: data).and_return(stub_result)
      described_class.query('querytext', rows: 2)
    end

    it "allows callers to specify HTTP GET method" do
      params = { rows: 2, q: 'querytext', qt: 'standard' }
      expect(mock_conn).to receive(:get).with('select', params: params).and_return(stub_result)
      described_class.query('querytext', rows: 2, method: :get)
    end

    it "allows callers to specify HTTP POST method" do
      data = { rows: 2, q: 'querytext', qt: 'standard' }
      expect(mock_conn).to receive(:post).with('select', data: data).and_return(stub_result)
      described_class.query('querytext', rows: 2, method: :post)
    end

    it "raises if method not GET or POST" do
      data = { rows: 2, q: 'querytext', qt: 'standard' }
      expect(mock_conn).not_to receive(:head).with('select', data: data)
      expect do
        described_class.query('querytext', rows: 2, method: :head)
      end.to raise_error(RuntimeError, "Unsupported HTTP method for querying SolrService (:head)")
    end

    it "wraps the solr response documents in Solr hits" do
      data = { rows: 2, q: 'querytext', qt: 'standard' }
      expect(mock_conn).to receive(:post).with('select', data: data).and_return(stub_result)
      result = described_class.query('querytext', rows: 2)
      expect(result.size).to eq 1
      expect(result.first.id).to eq 'x'
    end

    it "warns about not passing rows" do
      allow(mock_conn).to receive(:post).and_return(stub_result)
      expect(Hyrax.logger).to receive(:warn).with(/^Calling Hyrax::SolrService\.get without passing an explicit value for ':rows' is not recommended/)
      described_class.query('querytext')
    end

    context "when use_valkyrie: true" do
      subject(:service) { described_class.new(use_valkyrie: true) }

      let(:doc) { { 'id' => 'valkyrie-x' } }

      it "uses valkyrie solr based on config query_index_from_valkyrie" do
        expect(mock_conn).to receive(:post).with('select', data: { q: 'querytext', qt: 'standard' }).and_return(stub_result)

        result = service.query('querytext')
        expect(result.first.id).to eq 'valkyrie-x'
      end
    end
  end

  describe ".commit" do
    it "calls solr" do
      expect(mock_conn).to receive(:commit)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      described_class.commit
    end

    context "when use_valkyrie: true" do
      subject(:service) { described_class.new(use_valkyrie: true) }

      it "uses valkyrie solr based on config query_index_from_valkyrie" do
        expect(mock_conn).to receive(:commit)

        service.commit
      end
    end
  end

  describe ".delete_by_query" do
    it "calls solr" do
      expect(mock_conn).to receive(:delete_by_query).with("*:*", params: {})
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      described_class.delete_by_query("*:*")
    end

    context "when use_valkyrie: true" do
      let(:service) { described_class.new(use_valkyrie: true) }

      it "uses valkyrie solr based on config query_index_from_valkyrie" do
        expect(mock_conn).to receive(:delete_by_query).with("*:*", params: {})

        service.delete_by_query("*:*")
      end
    end
  end

  describe ".delete" do
    before do
      expect(mock_conn).to receive(:delete_by_id) do |_, opts|
        expect(opts).to eq(params: { softCommit: true })
      end
    end

    it "calls solr" do
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      described_class.delete("fade_solr_id#01")
    end

    context "when use_valkyrie: true" do
      subject(:service) { described_class.new(use_valkyrie: true) }

      it "uses valkyrie solr based on config query_index_from_valkyrie" do
        expect(service.delete("fade_solr_id#01")).to eq true
      end
    end
  end

  describe ".wipe!" do
    it "calls solr" do
      expect(mock_conn).to receive(:delete_by_query).with("*:*", params: {})
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(mock_conn).to receive(:commit)
      described_class.wipe!
    end

    context "when use_valkyrie: true" do
      let(:service) { described_class.new(use_valkyrie: true) }

      it "uses valkyrie solr based on config query_index_from_valkyrie" do
        expect(mock_conn).to receive(:delete_by_query).with("*:*", params: {})
        expect(mock_conn).to receive(:commit)
        service.wipe!
      end
    end
  end

  describe '.instance' do
    let(:mock_instance) { double("instance", conn: mock_conn) }

    it 'is deprecated' do
      expect(mock_instance).to receive(:commit)
      allow(Deprecation).to receive(:warn)
      allow(described_class).to receive(:instance).and_return(mock_instance)
      described_class.instance.commit
    end
  end

  describe "#add" do
    let(:mock_doc) { { "id" => "test_solr_doc#01" } }

    before do
      expect(mock_conn).to receive(:add) do |_, opts|
        expect(opts).to eq(params: { softCommit: true })
      end
    end

    it "calls solr" do
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.add(mock_doc)).to eq true
    end

    context "when use_valkyrie: true" do
      subject(:service) { described_class.new(use_valkyrie: true) }

      it "uses valkyrie solr based on config query_index_from_valkyrie" do
        expect(service.add(mock_doc)).to eq true
      end
    end
  end

  describe "#count" do
    let(:stub_result) { { 'response' => { 'numFound' => '2' } } }

    it "calls solr" do
      data = { rows: 0, q: 'querytext', qt: 'standard' }
      expect(mock_conn).to receive(:post).with('select', data: data).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.count('querytext')).to eq 2
    end

    context "when use_valkyrie: true" do
      subject(:service) { described_class.new(use_valkyrie: true) }

      it "uses valkyrie solr based on config query_index_from_valkyrie" do
        expect(mock_conn).to receive(:post).with('select', data: { rows: 0, q: 'querytext', qt: 'standard' }).and_return(stub_result)
        expect(service.count('querytext')).to eq 2
      end
    end
  end

  describe "#search_by_id" do
    context "with a document in solr" do
      let(:doc) { instance_double(Hash) }

      before do
        expect(described_class).to receive(:query).with('id:a_fade_id', hash_including(rows: 1)).and_return([doc])
      end

      it "returns the document" do
        expect(described_class.search_by_id('a_fade_id')).to eq doc
      end
    end

    context "without a document in solr" do
      before do
        expect(described_class).to receive(:query).with('id:a_fade_id', hash_including(rows: 1)).and_return([])
      end

      it "returns the document" do
        expect { described_class.search_by_id('a_fade_id') }.to raise_error Hyrax::ObjectNotFoundError, "Object 'a_fade_id' not found in solr"
      end
    end
  end
end
