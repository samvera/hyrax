require 'spec_helper'

describe RoleMapper do
  before do
    class Rails; end
    
    Rails.stub(:root).and_return('spec/support')
    Rails.stub(:env).and_return('test')
  end
  
  it "should define the 4 roles" do
    RoleMapper.role_names.sort.should == %w(admin_policy_object_editor archivist donor patron researcher) 
  end
  it "should quer[iy]able for roles for a given user" do
    RoleMapper.roles('leland_himself@example.com').sort.should == ['archivist', 'donor', 'patron']
    RoleMapper.roles('archivist2@example.com').should == ['archivist']
  end

  it "should return an empty array if there are no roles" do
    RoleMapper.roles('zeus@olympus.mt').empty?.should == true
  end
  it "should know who is what" do
    RoleMapper.whois('archivist').sort.should == %w(archivist1@example.com archivist2@example.com leland_himself@example.com)
    RoleMapper.whois('salesman').empty?.should == true
    RoleMapper.whois('admin_policy_object_editor').sort.should == %w(archivist1@example.com)
  end

end
