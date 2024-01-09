# frozen_string_literal: true
require 'spec_helper'

# NOTE: This job communicates exclusively with Fedora.
RSpec.describe ImportExportJob, :active_fedora do
  let(:work)    { create(:work) }
  let(:job)     { described_class.new }

  describe "when exporting" do
    let(:command) do
      "java -jar tmp/fcrepo-import-export.jar --mode export --resource #{work.uri} --dir tmp/descriptions"
    end

    it "runs the export command" do
      expect(job).to receive(:internal_call).with(command)
      job.perform(resource: work.uri.to_s)
    end
  end

  describe "when importing" do
    let(:command) do
      "java -jar tmp/fcrepo-import-export.jar --mode import --resource #{work.uri} --dir tmp/descriptions"
    end

    it "runs the import command" do
      expect(job).to receive(:internal_call).with(command)
      job.perform(resource: work.uri.to_s, mode: "import")
    end
  end
end
