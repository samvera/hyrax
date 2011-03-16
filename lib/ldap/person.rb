require 'net/ldap'

module Ldap
  
  class Person
    
    attr_reader :ldap_vals
    
    # create a new Person based on the provided computing ID
    def initialize(computing_id)
      do_ldap_lookup(computing_id)
    end
    
    def do_ldap_lookup(computing_id)
      ldap = Net::LDAP.new(:host => LDAP_HOST, :base => LDAP_BASE)
      filter = Net::LDAP::Filter.eq( LDAP_USER_ID, computing_id)
      attrs = []
      @ldap_vals = {}
      ldap.search( :base => LDAP_BASE, :attributes => attrs, :filter => filter, :return_result => true ) do |entry|
        entry.attribute_names.each do |n|
          @ldap_vals[n] = entry[n]
        end
      end
    end
    
    def first_name
      @ldap_vals[LDAP_FIRST_NAME.to_sym].first rescue ""
    end
    
    def last_name
      @ldap_vals[LDAP_LAST_NAME.to_sym].first rescue ""
    end
    
    def computing_id
      @ldap_vals[LDAP_COMPUTING_ID.to_sym].first rescue ""
    end
    
    def institution
      @ldap_vals.empty? ? "" : LDAP_INSTITUTION
    end
    
    def department
      @ldap_vals[LDAP_DEPARTMENT.to_sym].first rescue ""
    end
    
    def photo
      @ldap_vals[LDAP_PHOTO.to_sym].first rescue ""
    end
    
    def has_photo?
      @ldap_vals.has_key?(LDAP_PHOTO.to_sym) ? true : false
    end
  
  end
  

end
