# frozen_string_literal: true
require 'hyrax/move_all_works_to_admin_set'

RSpec.describe MoveAllWorksToAdminSet, :active_fedora, :clean_repo do
  subject { described_class.run(admin_set) }

  let(:admin_set) { create(:admin_set) }
  let!(:work) { create(:work) }

  it "moves the work into the admin set" do
    subject
    expect(work.reload.admin_set).to eq admin_set
  end
end
