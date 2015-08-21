require 'spec_helper'

describe ActiveFedoraIdBasedJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:file) do
    GenericFile.create do |gf|
      gf.apply_depositor_metadata(user)
    end
  end

  it 'finds object' do
    job = described_class.new(file.id)
    expect(job.generic_file).not_to be_nil
  end
end
