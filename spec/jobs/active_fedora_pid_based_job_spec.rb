require 'spec_helper'

describe ActiveFedoraPidBasedJob do
  let (:user) {FactoryGirl.find_or_create(:jill)}
  let (:file) {GenericFile.new.tap do |gf|
                  gf.apply_depositor_metadata(user)
                  gf.save!
                end}
  after do
    file.destroy
    user.destroy
  end
  it "finds object" do
    job = ActiveFedoraPidBasedJob.new(file.id)
    expect(job.generic_file).to_not be_nil
  end
end
