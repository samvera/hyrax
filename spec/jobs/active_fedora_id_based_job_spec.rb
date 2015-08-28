require 'spec_helper'

describe ActiveFedoraIdBasedJob do
  let(:generic_file) { GenericFile.new }
  let(:generic_file_id) { 'abc123' }

  before do
    allow(ActiveFedora::Base).to receive(:find).with(generic_file_id).and_return(generic_file)
  end

  it 'finds object' do
    job = described_class.new
    job.id = generic_file_id
    expect(job.generic_file).to eq generic_file
  end
end
