describe Sufia::CatalogSearchBuilder do
  let(:context) { double }
  let(:builder) { described_class.new(context).with(blacklight_params) }
  let(:solr_params) { Blacklight::Solr::Request.new }
  let(:blacklight_params) { { q: user_query } }
  let(:user_query) { "find me" }

  describe "#show_works_or_works_that_contain_files" do
    subject { builder.show_works_or_works_that_contain_files(solr_params) }

    context "with a user query" do
      it "creates a valid solr join for works and files" do
        subject
        expect(solr_params[:user_query]).to eq user_query
        expect(solr_params[:q]).to eq "{!lucene}_query_:\"{!dismax v=$user_query}\" _query_:\"{!join from=id to=file_set_ids_ssim}{!dismax v=$user_query}\""
      end
    end

    context "without a user query" do
      let(:blacklight_params) { {} }
      it "does not modify the query" do
        subject
        expect(solr_params[:user_query]).to be_nil
        expect(solr_params[:q]).to be_nil
      end
    end

    context "when doing a fielded search" do
      let(:blacklight_params) { { q: user_query, search_field: 'depositor' } }
      # Blacklight sets up these values when we've done a fielded search.
      # Here we're ensuring they aren't wiped out
      let(:solr_params) { Blacklight::Solr::Request.new("q" => "{!qf=depositor_ssim pf=depositor_ssim}\"#{user_query}\"") }
      it "does not modify the query" do
        subject
        expect(solr_params[:user_query]).to be_nil
        expect(solr_params[:q]).to eq '{!qf=depositor_ssim pf=depositor_ssim}"find me"'
      end
    end
  end
end
