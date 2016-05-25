describe Sufia::SearchBuilder do
  let(:builder) { described_class.new([], self) }
  let(:solr_params) { { q: user_query } }

  context "with a user query" do
    let(:user_query) { "find me" }
    it "creates a valid solr join for works and files" do
      builder.show_works_or_works_that_contain_files(solr_params)
      expect(solr_params[:user_query]).to eq user_query
      expect(solr_params[:q]).to eq "{!lucene}_query_:\"{!dismax v=$user_query}\" _query_:\"{!join from=id to=file_set_ids_ssim}{!dismax v=$user_query}\""
    end
  end

  context "with out a user query" do
    let(:user_query) { nil }
    it "does not modify the query" do
      builder.show_works_or_works_that_contain_files(solr_params)
      expect(solr_params[:user_query]).to be_nil
      expect(solr_params[:q]).to be_nil
    end
  end
end
