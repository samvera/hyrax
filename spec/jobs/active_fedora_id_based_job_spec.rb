require 'spec_helper'

describe ActiveFedoraIdBasedJob do
  let(:file_set) { FileSet.new }
  let(:file_set_id) { 'abc123' }

  before do
    allow(ActiveFedora::Base).to receive(:find).with(file_set_id).and_return(file_set)
  end

  it 'finds object' do
    job = described_class.new
    job.id = file_set_id
    expect(job.file_set).to eq file_set
  end
end
