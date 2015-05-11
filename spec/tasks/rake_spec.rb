require 'spec_helper'
require 'rake'

describe "Rake tasks" do

  describe "sufia:empty_batches" do
    before do
      load File.expand_path("../../../sufia-models/lib/tasks/batch_cleanup.rake", __FILE__)
      Rake::Task.define_task(:environment)
    end
    after { Rake::Task["sufia:empty_batches"].reenable }
    subject { capture_stdout { Rake::Task["sufia:empty_batches"].invoke } }
    
    context "without an empty batch" do
      it { is_expected.to be_empty }
    end
    
    context "with an empty batch" do
      before { Batch.create("empty-batch") }
      it { is_expected.to start_with("empty-batch contains no files - to delete, rerun with the remove option") }
      
      describe "removing the empty batch" do
        subject { capture_stdout { Rake::Task["sufia:empty_batches"].invoke("remove") } }
        it { is_expected.to start_with("empty-batch contains no files - deleted") }
      end
    end
  end

  describe "sufia:migrate" do
    let(:namespaced_id) { "sufia:123" }
    let(:corrected_id)  { "123" }
    before do
      load File.expand_path("../../../sufia-models/lib/tasks/migrate.rake", __FILE__)
      Rake::Task.define_task(:environment)
    end

    describe "deleting the namespace from ProxyDepositRequest#generic_work_id" do
      let(:sender) { FactoryGirl.find_or_create(:jill) }
      let(:receiver) { FactoryGirl.find_or_create(:archivist) }
      before do
        ProxyDepositRequest.create(generic_work_id: namespaced_id, sending_user: sender, receiving_user: receiver, sender_comment: "please take this")
        Rake::Task["sufia:migrate:proxy_deposits"].invoke
      end
      subject { ProxyDepositRequest.first.generic_work_id }
      it { is_expected.to eql corrected_id }
    end

    describe "deleting the namespace from ChecksumAuditLog#generic_file_id" do
      before do
        ChecksumAuditLog.create(generic_file_id: namespaced_id)
        Rake::Task["sufia:migrate:audit_logs"].invoke
      end
      subject { ChecksumAuditLog.first.generic_file_id }
      it { is_expected.to eql corrected_id }
    end
  end

end
