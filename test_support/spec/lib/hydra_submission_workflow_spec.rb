require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )

mods_asset_model = "info:fedora/afmodel:ModsAsset"

describe Hydra::SubmissionWorkflow do
  before(:each) do
    @document = SolrDocument.new({:has_model_s => [mods_asset_model]})
  end
  include Hydra::SubmissionWorkflow
  
  describe "first step in workflow" do
    it "should return the first step of a given workflow" do
      first_step_in_workflow.should == "contributor"
    end
  end
  
  describe "next in workflow" do
    it "should provide the next step based on the provided step" do
      next_step_in_workflow(:contributor).should == "publication"
    end
    it "should return nil if there is no step (denoting the last step)" do
      next_step_in_workflow(:permissions).should be_nil
    end
    it "should return the step after the first if a blank current step is provided (e.g. started from the first step so no wf_step param)" do
      next_step_in_workflow(nil).should == "publication"
      next_step_in_workflow("").should == "publication"
    end
  end

  describe "partial for step" do
    it "should return the partial for the given step" do
      workflow_partial_for_step(:contributor).should match(/contributor_form/)
    end
  end

  describe "previous show partials" do
    it "should return all of the previous show partials for display in the HTML-only workflow" do
      prev_partials = previous_show_partials(:permissions)
      prev_partials.is_a?(Array).should be_true
      prev_partials.length.should == 4
      prev_partials.first.should match(/mods.*contributors/)
      prev_partials.last.should match(/mods.*file_assets/)
    end
    it "should return an empty array for the first step in the workflow" do
      previous_show_partials(:contributor).should == []
      previous_show_partials("").should == []
    end
  end

  describe "model specific configurations" do
    it "should return the appropriate configuration when an @document object is available" do
      config = model_config
      config.is_a?(Array).should be_true
      config.length.should == 5
      partial_is_mods = []
      config.each do |c|
        c.is_a?(Hash).should be_true
        c.has_key?(:name).should be_true
        c.has_key?(:edit_partial).should be_true
        partial_is_mods << c[:edit_partial].include?("mods_assets")
      end
      partial_is_mods.include?(true).should be_true
    end
    it "should return the appropriate config when a model is available in the params hash" do
      @document = nil
      to = SubmissionWorkflowObject.new
      to.stubs(:params).returns({:content_type => "generic_content"})
      config = to.model_config
      config.is_a?(Array).should be_true
      config.length.should == 4
      partial_is_generic = []
      config.each do |c|
        c.is_a?(Hash).should be_true
        c.has_key?(:name).should be_true
        c.has_key?(:edit_partial).should be_true
        partial_is_generic << c[:edit_partial].include?("generic_content")
      end
      partial_is_generic.include?(true).should be_true
    end
    it "should return the appropriate config when the ID of an object is available in the params hash" do
      @document = nil
      to = SubmissionWorkflowObject.new
      to.stubs(:params).returns({:id=>"hydrangea:fixture_mods_article1"})
      config = to.model_config
      config.is_a?(Array).should be_true
      config.length.should == 5
      config.each do |c|
        c.is_a?(Hash).should be_true
        c.has_key?(:name).should be_true
        c.has_key?(:edit_partial).should be_true
      end
    end
    it "should return the configuration for non mods assets (generic_content)" do
      @document = nil
      to = SubmissionWorkflowObject.new
      to.stubs(:params).returns(:id=>"hydra:test_generic_content")
      config = to.model_config
      config.is_a?(Array).should be_true
      config.length.should == 4
      partial_is_generic = []
      config.each do |c|
        c.is_a?(Hash).should be_true
        c.has_key?(:name).should be_true
        c.has_key?(:edit_partial).should be_true
        partial_is_generic << c[:edit_partial].include?("generic_content")
      end
      partial_is_generic.include?(true).should be_true
    end
    it "should return nil if an ID is the only context available and it is not a valid object" do
      @document = nil
      to = SubmissionWorkflowObject.new
      to.stubs(:params).returns(:id=>"hydra:not_an_actual_record")
      to.model_config.should be_nil
    end
  end
  describe "before_filter validation" do
    it "should redirect back when the validation method returns false." do
      @document = nil
      to = SubmissionWorkflowObject.new
      to.stubs(:params).returns({:id=>"hydrangea:fixture_mods_article1",:action=>"create"})
      to.expects(:redirect_to).with(:back)
      to.validate_workflow_step
    end
    it "should not redirect when the validation method returns true." do
      @document = nil
      to = SubmissionWorkflowObject.new
      to.stubs(:params).returns({:id=>"hydrangea:fixture_mods_article1",:action=>"update"})
      to.expects(:redirect_to).never
      to.validate_workflow_step
    end
  end
end
class SubmissionWorkflowObject
  include Hydra::SubmissionWorkflow
  def mods_assets_create_validation
    return false
  end
  def mods_assets_update_validation
    return true
  end
end