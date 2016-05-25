describe AuthoritiesController, type: :controller do
  describe "#query" do
    it "returns an array of hashes" do
      mock_hits = [{ label: "English", uri: "http://example.org/eng" },
                   { label: "Environment", uri: "http://example.org/env" },
                   { label: "Edge", uri: "http://example.org/edge" },
                   { label: "Edgar", uri: "http://example.org/edga" },
                   { label: "Eddie", uri: "http://example.org/edd" },
                   { label: "Economics", uri: "http://example.org/eco" }]
      expect(LocalAuthority).to receive(:entries_by_term).and_return(mock_hits)
      xhr :get, :query, model: "file_sets", term: "subject", q: "E"
      expect(response).to be_success
      expect(JSON.parse(response.body).count).to eq(6)
      expect(JSON.parse(response.body)[0]["label"]).to eq("English")
      expect(JSON.parse(response.body)[0]["uri"]).to eq("http://example.org/eng")
    end
  end
end
