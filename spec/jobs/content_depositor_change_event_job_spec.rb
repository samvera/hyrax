require 'spec_helper'

describe ContentDepositorChangeEventJob do
  let!(:depositor) { FactoryGirl.find_or_create(:jill) }
  let!(:receiver) { FactoryGirl.find_or_create(:archivist) }
  let!(:file) do
    FileSet.create! do |f|
      f.apply_depositor_metadata(depositor.user_key)
    end
  end
  let!(:work) do
    GenericWork.create!(title: ['Test work']) do |w|
      w.apply_depositor_metadata(depositor.user_key)
    end
  end

  before do
    work.members << file
    described_class.perform_now(work.id, receiver.user_key)
  end

  it "changes the depositor and records an original depositor" do
    work.reload
    expect(work.depositor).to eq receiver.user_key
    expect(work.proxy_depositor).to eq depositor.user_key
    expect(work.edit_users).to include(receiver.user_key, depositor.user_key)
  end

  it "changes the depositor of the child file sets" do
    file.reload
    expect(file.depositor).to eq receiver.user_key
    expect(file.edit_users).to include(receiver.user_key, depositor.user_key)
  end
end
