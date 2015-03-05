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

end
