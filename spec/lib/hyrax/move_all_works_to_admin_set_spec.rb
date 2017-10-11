require 'hyrax/move_all_works_to_admin_set'

RSpec.describe MoveAllWorksToAdminSet, :clean_repo do
  subject { described_class.run(admin_set) }

  let(:admin_set) { create_for_repository(:admin_set) }
  let!(:work) { create_for_repository(:work) }

  it "moves the work into the admin set" do
    subject
    expect(work.reload.admin_set).to eq admin_set
  end
end
