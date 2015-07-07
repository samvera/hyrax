require 'spec_helper'
require 'rake'

describe "Rake tasks" do

  # TODO: it's not clear whether Batch should come over.
  # See: https://github.com/projecthydra-labs/curation_concerns/issues/29
  # describe "curation_concerns:empty_batches" do
  #   before do
  #     load File.expand_path("../../../curation_concerns-models/lib/tasks/batch_cleanup.rake", __FILE__)
  #     Rake::Task.define_task(:environment)
  #   end
  #   after { Rake::Task["curation_concerns:empty_batches"].reenable }
  #   subject { capture_stdout { Rake::Task["curation_concerns:empty_batches"].invoke } }
  #
  #   context "without an empty batch" do
  #     it { is_expected.to be_empty }
  #   end
  #
  #   context "with an empty batch" do
  #     before { Batch.create("empty-batch") }
  #     it { is_expected.to start_with("empty-batch contains no files - to delete, rerun with the remove option") }
  #
  #     describe "removing the empty batch" do
  #       subject { capture_stdout { Rake::Task["curation_concerns:empty_batches"].invoke("remove") } }
  #       it { is_expected.to start_with("empty-batch contains no files - deleted") }
  #     end
  #   end
  # end

  describe "curation_concerns:migrate" do
    let(:namespaced_id) { "curation_concerns:123" }
    let(:corrected_id)  { "123" }
    before do
      load File.expand_path("../../../curation_concerns-models/lib/tasks/migrate.rake", __FILE__)
      Rake::Task.define_task(:environment)
    end

    describe "deleting the namespace from ChecksumAuditLog#generic_file_id" do
      before do
        ChecksumAuditLog.create(generic_file_id: namespaced_id)
        Rake::Task["curation_concerns:migrate:audit_logs"].invoke
      end
      subject { ChecksumAuditLog.first.generic_file_id }
      it { is_expected.to eql corrected_id }
    end
  end

end
