# Need way to find way to stub current_user and RoleMapper in order to run these tests
require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )

describe Hydra::AccessControlsEnforcement do
 describe "build_lucene_query" do

   it "should return fields for all roles the user is a member of checking against the discover, access, read fields" do
     stub_user = User.new
     stub_user.stubs(:is_being_superuser?).returns false
     helper.stubs(:current_user).returns(stub_user)
     RoleMapper.stubs(:roles).with(stub_user.login).returns(["archivist", "researcher"])
     
     query = helper.send(:build_lucene_query, "string")
     
     ["discover","edit","read"].each do |type|
       query.should match(/_query_\:\"#{type}_access_group_t\:archivist/) and
       query.should match(/_query_\:\"#{type}_access_group_t\:researcher/)
     end
   end
   it "should return fields for all the person specific discover, access, read fields" do
     stub_user = User.new
     stub_user.stubs(:is_being_superuser?).returns false
     helper.stubs(:current_user).returns(stub_user)
     query = helper.send(:build_lucene_query, "string")
     ["discover","edit","read"].each do |type|
       query.should match(/_query_\:\"#{type}_access_person_t\:#{stub_user.login}/)
     end
   end
   describe "for superusers" do
     it "should return superuser access level" do
       stub_user = User.new
       stub_user.stubs(:is_being_superuser?).returns true
       helper.stubs(:current_user).returns(stub_user)
       query = helper.send(:build_lucene_query, "string")
       ["discover","edit","read"].each do |type|         
         query.should match(/_query_\:\"#{type}_access_person_t\:\[\* TO \*\]/)
       end
     end
     it "should not return superuser access to non-superusers" do
       stub_user = User.new
       stub_user.stubs(:is_being_superuser?).returns false
       helper.stubs(:current_user).returns(stub_user)
       query = helper.send(:build_lucene_query, "string")
       ["discover","edit","read"].each do |type|
         query.should_not match(/_query_\:\"#{type}_access_person_t\:\[\* TO \*\]/)
       end
     end
   end

 end
end


