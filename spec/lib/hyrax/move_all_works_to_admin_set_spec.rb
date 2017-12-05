require 'hyrax/move_all_works_to_admin_set'

RSpec.describe MoveAllWorksToAdminSet, :clean_repo do
  subject { described_class.run(admin_set) }

  let(:admin_set) { create_for_repository(:admin_set) }
  let!(:work) { create_for_repository(:work) }

  it "moves the work into the admin set" do
    subject
    reloaded = Hyrax::Queries.find_by(id: work.id)
    expect(reloaded.admin_set_id).to eq admin_set.id
  end
end
