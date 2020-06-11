# frozen_string_literal: true
RSpec.describe Hyrax::Collections::SearchService do
  let(:login) { 'vanessa' }
  let(:session) { { history: [17, 14, 12, 9] } }
  let(:service) { described_class.new(session, login) }

  it "gets the documents for the first history entry" do
    expect(Search).to receive(:find).with(17).and_return(Search.new(query_params: { q: "World Peace" }))
    expect(service).to receive(:get_search_results).and_return([:one, [:doc1, :doc2]])
    expect(service.last_search_documents).to eq([:doc1, :doc2])
  end

  describe 'apply_gated_search' do
    before do
      allow(::User.group_service).to receive(:roles).with(login).and_return(['umg/test.group.1'])
    end

    let(:params) { service.apply_gated_search({}, {}) }
    let(:group_query) { params[:fq].first.split(' OR ')[1] }

    it "escapes slashes in groups" do
      expect(group_query).to eq('edit_access_group_ssim:umg\/test.group.1')
    end

    context "when Solr's access control suffix is overridden" do
      let(:service) { described_class.new({}, '') }

      it "uses the overriden value" do
        allow(service).to receive(:solr_access_control_suffix).and_return("edit_group_customfield")
        params = service.apply_gated_search({}, {})
        public_query = params[:fq].first.split(' OR ')[0]
        expect(public_query).to eq('edit_group_customfield:public')
      end
    end
  end
end
