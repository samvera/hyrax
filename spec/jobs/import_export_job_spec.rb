require 'spec_helper'

describe ImportExportJob do
  let(:work)    { create(:work) }
  let(:job)     { described_class.new(work.uri.to_s) }
  let(:command) do
    "java -jar tmp/fcrepo-import-export.jar --mode export --resource #{work.uri} --descDir tmp/descriptions --binDir tmp/binaries"
  end

  it "exports the work" do
    expect(job).to receive(:internal_call).with(command)
    job.perform(work.uri.to_s)
  end
end
