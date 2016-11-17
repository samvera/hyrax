require 'spec_helper'

describe ImportExportJob do
  let(:work)    { create(:work) }
  let(:job)     { described_class.new(work.uri.to_s) }

  describe "when exporting" do
    let(:command) do
      "java -jar tmp/fcrepo-import-export.jar --mode export --resource #{work.uri} --descDir tmp/descriptions --binDir tmp/binaries"
    end

    it "runs the export command" do
      expect(job).to receive(:internal_call).with(command)
      job.perform(work.uri.to_s)
    end
  end

  describe "when importing" do
    let(:command) do
      "java -jar tmp/fcrepo-import-export.jar --mode import --resource #{work.uri} --descDir tmp/descriptions --binDir tmp/binaries"
    end

    it "runs the import command" do
      expect(job).to receive(:internal_call).with(command)
      job.perform(work.uri.to_s, mode: "import")
    end
  end
end
