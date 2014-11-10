require 'spec_helper'

describe ContentDepositorChangeEventJob do
  before do
    @depositor = FactoryGirl.find_or_create(:jill)
    @receiver = FactoryGirl.find_or_create(:archivist)
    @file = ::GenericFile.new.tap do |gf|
      gf.apply_depositor_metadata(@depositor.user_key)
      gf.save!
    end
    ContentDepositorChangeEventJob.new(@file.id, @receiver.user_key).run
  end

  it "changes the depositor and records an original depositor" do
    @file.reload
    expect(@file.depositor).to eq @receiver.user_key
    expect(@file.proxy_depositor).to eq @depositor.user_key
    expect(@file.edit_users).to include(@receiver.user_key, @depositor.user_key)
  end
end
