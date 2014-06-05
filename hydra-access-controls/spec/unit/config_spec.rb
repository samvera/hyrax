require 'spec_helper'
describe Hydra::Config do
  let (:config) { subject }
  it "Should accept a hash based config" do
      # This specifies the solr field names of permissions-related fields.
      # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
      # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
      config[:permissions] = {
        :discover => {:group =>ActiveFedora::SolrService.solr_name("discover_access_group", :symbol), :individual=>ActiveFedora::SolrService.solr_name("discover_access_person", :symbol)},
        :read => {:group =>ActiveFedora::SolrService.solr_name("read_access_group", :symbol), :individual=>ActiveFedora::SolrService.solr_name("read_access_person", :symbol)},
        :edit => {:group =>ActiveFedora::SolrService.solr_name("edit_access_group", :symbol), :individual=>ActiveFedora::SolrService.solr_name("edit_access_person", :symbol)},
        :owner => ActiveFedora::SolrService.solr_name("depositor", :symbol),
        :embargo_release_date => ActiveFedora::SolrService.solr_name("embargo_release_date", Solrizer::Descriptor.new(:date, :stored, :indexed))
      }

      # specify the user model
      config[:user_model] = 'User'

      config[:permissions][:edit][:individual].should == 'edit_access_person_ssim'
  end

  it "should accept a struct based config" do
      # This specifies the solr field names of permissions-related fields.
      # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
      # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
      config.permissions.discover.group = ActiveFedora::SolrService.solr_name("discover_access_group", :symbol)

      # specify the user model
      config.user_model = 'User'

      config.permissions.discover.group.should == 'discover_access_group_ssim'
      config.user_model.should == 'User'
  end

  it "should have inheritable attributes" do
      config[:permissions][:inheritable][:edit][:individual].should == 'inheritable_edit_access_person_ssim'
  end
  it "should have a nil policy_class" do
      config[:permissions][:policy_class].should be_nil
  end

  it "should have defaults" do
    config.permissions.read.individual.should == 'read_access_person_ssim'
    config.permissions.embargo_release_date.should == 'embargo_release_date_dtsi'
    config.permissions.embargo.release_date.should == 'embargo_release_date_dtsi'
    config.user_model.should == 'User'
  end

end
