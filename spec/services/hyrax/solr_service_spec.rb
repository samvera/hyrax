RSpec.describe Hyrax::SolrService do
  let(:mock_conn) { instance_double(RSolr::Client) }

  describe '.select_path' do
    it 'raises NotImplementedError' do
      expect { described_class.select_path }.to raise_error NotImplementedError
    end
  end

  describe "#get" do
    it "calls solr" do
      stub_result = double("Result")
      expect(mock_conn).to receive(:get).with('select', params: { q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.get('querytext')).to eq stub_result
    end

    it "uses args as params" do
      stub_result = double("Result")
      expect(mock_conn).to receive(:get).with('select', params: { fq: ["id:\"1234\""], q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.get('querytext', fq: ["id:\"1234\""])).to eq stub_result
    end

    it "uses the valkyrie solr core" do
      service = described_class.new
      stub_result = double("Valkyrie Result")
      expect(mock_conn).to receive(:get).with('select', params: { q: 'querytext' }).and_return(stub_result)
      allow(service).to receive(:valkyrie_index).and_return(double("valkyrie_index", connection: mock_conn))
      expect(service.get('querytext', use_valkyrie: true)).to eq stub_result
    end
  end

  describe "#post" do
    it "calls solr" do
      stub_result = double("Result")
      expect(mock_conn).to receive(:post).with('select', data: { q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.post('querytext')).to eq stub_result
    end

    it "uses args as data" do
      stub_result = double("Result")
      expect(mock_conn).to receive(:post).with('select', data: { fq: ["id:\"1234\""], q: 'querytext', qt: 'standard' }).and_return(stub_result)
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      expect(described_class.post('querytext', fq: ["id:\"1234\""])).to eq stub_result
    end

    it "uses the valkyrie solr core" do
      service = described_class.new
      stub_result = double("Valkyrie Result")
      expect(mock_conn).to receive(:post).with('select', data: { q: 'querytext' }).and_return(stub_result)
      allow(service).to receive(:valkyrie_index).and_return(double("valkyrie_index", connection: mock_conn))
      expect(service.post('querytext', use_valkyrie: true)).to eq stub_result
    end
  end

  describe "#query" do
    let(:doc) { { 'id' => 'x' } }
    let(:docs) { [doc] }
    let(:stub_result) { { 'response' => { 'docs' => docs } } }

    before do
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
    end

    it "defaults to HTTP GET method" do
      expect(mock_conn).to receive(:get).with('select', params: { rows: 2, q: 'querytext', qt: 'standard' }).and_return(stub_result)
      described_class.query('querytext', rows: 2)
    end

    it "allows callers to specify HTTP POST method" do
      expect(mock_conn).to receive(:post).with('select', data: { rows: 2, q: 'querytext', qt: 'standard' }).and_return(stub_result)
      described_class.query('querytext', rows: 2, method: :post)
    end

    it "raises if method not GET or POST" do
      expect(mock_conn).not_to receive(:head).with('select', data: { rows: 2, q: 'querytext', qt: 'standard' })
      expect do
        described_class.query('querytext', rows: 2, method: :head)
      end.to raise_error(RuntimeError, "Unsupported HTTP method for querying SolrService (:head)")
    end

    it "wraps the solr response documents in Solr hits" do
      expect(mock_conn).to receive(:get).with('select', params: { rows: 2, q: 'querytext', qt: 'standard' }).and_return(stub_result)
      result = described_class.query('querytext', rows: 2)
      expect(result.size).to eq 1
      expect(result.first.id).to eq 'x'
    end

    it "warns about not passing rows" do
      allow(mock_conn).to receive(:get).and_return(stub_result)
      expect(Rails.logger).to receive(:warn).with(/^Calling Hyrax::SolrService\.get without passing an explicit value for ':rows' is not recommended/)
      described_class.query('querytext')
    end

    context "when use_valkyrie: true" do
      let(:doc) { { 'id' => 'valkyrie-x' } }

      it "accepts and passes through use_valkyrie:true" do
        service = described_class.new
        expect(mock_conn).to receive(:get).with('select', params: { q: 'querytext' }).and_return(stub_result)
        allow(service).to receive(:valkyrie_index).and_return(double("valkyrie_index", connection: mock_conn))
        result = service.query('querytext', use_valkyrie: true)
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
      let(:service) { described_class.new }

      it "accepts and passes through use_valkyrie:true" do
        expect(mock_conn).to receive(:commit)
        allow(service).to receive(:valkyrie_index).and_return(double("valkyrie_index", connection: mock_conn))
        service.commit use_valkyrie: true
      end
    end
  end

  describe ".delete_by_query" do
    it "calls solr" do
      expect(mock_conn).to receive(:delete_by_query).with("*:*", params:{})
      allow(described_class).to receive(:instance).and_return(double("instance", conn: mock_conn))
      described_class.delete_by_query("*:*")
    end

    context "when use_valkyrie: true" do
      let(:service) { described_class.new }

      it "accepts and passes through use_valkyrie:true" do
        expect(mock_conn).to receive(:delete_by_query).with("*:*", params:{})
        allow(service).to receive(:valkyrie_index).and_return(double("valkyrie_index", connection: mock_conn))
        service.delete_by_query("*:*", use_valkyrie: true)
      end
    end
  end
end
