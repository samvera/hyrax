# frozen_string_literal: true
RSpec.describe Hyrax::AdminSetMemberService, clean_repo: true do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:repository) { Blacklight::Solr::Repository.new(blacklight_config) }
  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { double('Scope', current_ability: current_ability, repository: repository, blacklight_config: blacklight_config) }

  let(:admin_set) { build(:admin_set) }
  let(:builder) { described_class.new(scope: scope, collection: admin_set, params: { "id" => admin_set.id.to_s }) }
  let(:subject) { builder.available_member_works }
  let(:ids) { subject.response[:docs].map { |col| col[:id] } }

  describe '#available_member_works' do
    let!(:work1) { create(:generic_work, admin_set: admin_set) }
    let!(:work2) { create(:generic_work) }
    let!(:work3) { create(:generic_work, admin_set: admin_set) }

    it 'returns the members of the admin set' do
      expect(ids).to contain_exactly(work1.id, work3.id)
    end
  end
end
