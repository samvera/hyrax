RSpec.describe Qa::Authorities::Collections, :clean_repo do
  let(:controller) { Qa::TermsController.new }
  let(:user1) { build(:user) }
  let(:user2) { build(:user) }
  let(:ability) { Ability.new(user1) }
  let(:q) { "foo" }
  let(:service) { described_class.new }

  let(:col1_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-1-own", "title_tesim" => ["foo foo"], "title_sim" => ["foo foo"],
      "edit_access_person_ssim" => [user1.user_key] }
  end
  let!(:col1_pt) { create(:permission_template, source_id: col1_doc[:id], source_type: 'collection', manage_users: [user1.user_key]) }
  let(:col2_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-2-own", "title_tesim" => ["bar"], "title_sim" => ["bar"],
      "edit_access_person_ssim" => [user1.user_key] }
  end
  let!(:col2_pt) { create(:permission_template, source_id: col2_doc[:id], source_type: 'collection', manage_users: [user1.user_key]) }
  let(:col3_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-3-own", "title_tesim" => ["another foo"], "title_sim" => ["another foo"],
      "edit_access_person_ssim" => [user1.user_key] }
  end
  let!(:col3_pt) { create(:permission_template, source_id: col3_doc[:id], source_type: 'collection', manage_users: [user1.user_key]) }
  let(:col4_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-4-none", "title_tesim" => ["foo foo foo"], "title_sim" => ["foo foo foo"],
      "edit_access_person_ssim" => [user2.user_key] }
  end
  let(:col5_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-5-mgr", "title_tesim" => ["foo for you"], "title_sim" => ["foo for you"],
      "edit_access_person_ssim" => [user1.user_key, user2.user_key] }
  end
  let!(:col5_pt) { create(:permission_template, source_id: col5_doc[:id], source_type: 'collection', manage_users: [user1.user_key]) }
  let(:col6_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-6-dep", "title_tesim" => ["foo too"], "title_sim" => ["foo too"],
      "edit_access_person_ssim" => [user2.user_key], "read_access_person_ssim" => [user1.user_key] }
  end
  let!(:col6_pt) { create(:permission_template, source_id: col6_doc[:id], source_type: 'collection', manage_users: [user2.user_key], deposit_users: [user1.user_key]) }
  let(:col7_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-7-view", "title_tesim" => ["foo bar baz"], "title_sim" => ["foo bar baz"],
      "edit_access_person_ssim" => [user2.user_key], "read_access_person_ssim" => [user1.user_key] }
  end
  let!(:col7_pt) { create(:permission_template, source_id: col7_doc[:id], source_type: 'collection', manage_users: [user2.user_key], view_users: [user1.user_key]) }
  let(:col8_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-8-mgr", "title_tesim" => ["bar for you"], "title_sim" => ["bar for you"],
      "edit_access_person_ssim" => [user1.user_key, user2.user_key] }
  end
  let!(:col8_pt) { create(:permission_template, source_id: col8_doc[:id], source_type: 'collection', manage_users: [user2.user_key, user1.user_key]) }
  let(:col9_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-9-dep", "title_tesim" => ["bar too"], "title_sim" => ["bar too"],
      "edit_access_person_ssim" => [user2.user_key], "read_access_person_ssim" => [user1.user_key] }
  end
  let!(:col9_pt) { create(:permission_template, source_id: col9_doc[:id], source_type: 'collection', manage_users: [user2.user_key], deposit_users: [user1.user_key]) }
  let(:col10_doc) do
    { "has_model_ssim" => ["Collection"], id: "col-10-view", "title_tesim" => ["bar bar baz"], "title_sim" => ["bar bar baz"],
      "edit_access_person_ssim" => [user2.user_key], "read_access_person_ssim" => [user1.user_key] }
  end
  let!(:col10_pt) { create(:permission_template, source_id: col10_doc[:id], source_type: 'collection', manage_users: [user2.user_key], view_users: [user1.user_key]) }

  before do
    ActiveFedora::SolrService.add(col1_doc, commit: true)
    ActiveFedora::SolrService.add(col2_doc, commit: true)
    ActiveFedora::SolrService.add(col3_doc, commit: true)
    ActiveFedora::SolrService.add(col4_doc, commit: true)
    ActiveFedora::SolrService.add(col5_doc, commit: true)
    ActiveFedora::SolrService.add(col6_doc, commit: true)
    ActiveFedora::SolrService.add(col7_doc, commit: true)
    ActiveFedora::SolrService.add(col8_doc, commit: true)
    ActiveFedora::SolrService.add(col9_doc, commit: true)
    ActiveFedora::SolrService.add(col10_doc, commit: true)

    allow(controller).to receive(:params).and_return(params)
    allow(controller).to receive(:current_user).and_return(user1)
    allow(controller).to receive(:current_ability).and_return(ability)
  end

  subject { service.search(q, controller) }

  describe '#search' do
    context 'when access is read' do
      let(:params) { ActionController::Parameters.new(q: q, access: 'read') }

      it 'displays a list of read collections for the current user' do
        expect(subject.map { |result| result[:id] }).to match_array [col1_doc[:id], col3_doc[:id], col5_doc[:id], col6_doc[:id], col7_doc[:id]]
      end
    end

    context 'when access is edit' do
      let(:params) { ActionController::Parameters.new(q: q, access: 'edit') }

      it 'displays a list of edit collections for the current user' do
        expect(subject.map { |result| result[:id] }).to match_array [col1_doc[:id], col3_doc[:id], col5_doc[:id]]
      end
    end

    context 'when access is deposit' do
      let(:params) { ActionController::Parameters.new(q: q, access: 'deposit') }

      it 'displays a list of edit and deposit collections for the current user' do
        expect(subject.map { |result| result[:id] }).to match_array [col1_doc[:id], col3_doc[:id], col5_doc[:id], col6_doc[:id]]
      end
    end
  end
end
