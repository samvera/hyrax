require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )

describe Hydra::SubmissionWorkflow do
  include Hydra::SubmissionWorkflow
  
  describe "first step in workflow" do
    it "should return the first step of a given workflow" do
      first_step_in_workflow.should == :contributor
    end
  end
  
  describe "next in workflow" do
    it "should provide the next step based on the provided step" do
      next_step_in_workflow(:contributor).should == :publication
    end
    it "should return nil if there is no step (denoting the last step)" do
      next_step_in_workflow(:permissions).should be_nil
    end
  end

  describe "partial for step" do
    it "should return the partial for the given step" do
      workflow_partial_for_step(:contributor).should == "mods_assets/contributor_form"
    end
  end

end
