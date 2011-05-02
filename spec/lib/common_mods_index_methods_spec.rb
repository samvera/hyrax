# Need way to find way to stub current_user and RoleMapper in order to run these tests
require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )


describe Hydra::CommonModsIndexMethods do
  describe "extract_person_full_names" do
    it "should return an array of Solr::Field objects for :person_full_name_facet" do
      full_names = ModsAsset.find("hydrangea:fixture_mods_article1").datastreams["descMetadata"].extract_person_full_names
      full_names.should be_kind_of Hash
      full_names["person_full_name_facet"].should be_kind_of Array
      full_names["person_full_name_facet"].length.should == 2
      full_names["person_full_name_facet"].first.should == "FAMILY NAME, GIVEN NAMES"
      full_names["person_full_name_facet"].last.should == "Lacks, Henrietta"
    end
  end
  describe "extract_person_organizations" do 
    it "should return an array of Solr::Field objects for :mods_organization_facet" do
      orgs = ModsAsset.find("hydrangea:fixture_mods_article1").datastreams["descMetadata"].extract_person_organizations
      orgs.should be_kind_of Hash
      orgs["mods_organization_facet"].should be_kind_of Array
      orgs["mods_organization_facet"].length.should == 2
      orgs["mods_organization_facet"].first.should == "FACULTY, UNIVERSITY"
      orgs["mods_organization_facet"].last.should == "Baltimore"
    end
  end
end


