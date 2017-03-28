require 'spec_helper'
describe Hydra::Config do
  let (:config) { subject }
  it "Should accept a hash based config" do
      # This specifies the solr field names of permissions-related fields.
      # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
      # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
      config[:permissions] = {
        discover: { group: ActiveFedora.index_field_mapper.solr_name("discover_access_group", :symbol),
                    individual: ActiveFedora.index_field_mapper.solr_name("discover_access_person", :symbol)},
        read: { group: ActiveFedora.index_field_mapper.solr_name("read_access_group", :symbol),
                individual: ActiveFedora.index_field_mapper.solr_name("read_access_person", :symbol)},
        edit: { group: ActiveFedora.index_field_mapper.solr_name("edit_access_group", :symbol),
                individual: ActiveFedora.index_field_mapper.solr_name("edit_access_person", :symbol)},
        owner: ActiveFedora.index_field_mapper.solr_name("depositor", :symbol),
      }
      config.permissions.embargo.release_date = ActiveFedora.index_field_mapper.solr_name("embargo_release_date", Solrizer::Descriptor.new(:date, :stored, :indexed))

      # specify the user model
      config[:user_model] = 'User'

      expect(config[:permissions][:edit][:individual]).to eq 'edit_access_person_ssim'
  end

  it "should accept a struct based config" do
      # This specifies the solr field names of permissions-related fields.
      # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
      # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
      config.permissions.discover.group = ActiveFedora.index_field_mapper.solr_name("discover_access_group", :symbol)

      # specify the user model
      config.user_model = 'User'

      expect(config.permissions.discover.group).to eq 'discover_access_group_ssim'
      expect(config.user_model).to eq 'User'
  end

  it "should have inheritable attributes" do
      expect(config[:permissions][:inheritable][:edit][:individual]).to eq 'inheritable_edit_access_person_ssim'
  end
  it "should have a nil policy_class" do
      expect(config[:permissions][:policy_class]).to be_nil
  end

  it "has defaults" do
    expect(config.permissions.read.individual).to eq 'read_access_person_ssim'
    expect(config.permissions.embargo.release_date).to eq 'embargo_release_date_dtsi'
    expect(config.user_model).to eq 'User'
    expect(config.user_key_field).to eq :email
  end

  describe "user_key_field" do
    after do
      # restore default
      config.user_key_field = :email
    end
    
    it "is settable" do
      config.user_key_field = :uid
      expect(config.user_key_field).to eq :uid
    end
  end
end
