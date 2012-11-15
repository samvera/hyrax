# A bucket to put ldap related methods into the user module
module Sufia::Ldap

  module User 
    extend ActiveSupport::Concern
    included do
      # Workaround to retry LDAP calls a number of times
      include ::Sufia::Utils
    end
    def populate_attributes
      #update exist cache
      exist = ldap_exist!
      logger.warn "No ldapentry exists for #{login}" unless exist
      return unless exist

      begin
        entry = directory_attributes.first
      rescue
        logger.warn "Error getting directory entry: #{Hydra::LDAP.connection.get_operation_result.message}"
        return
      end
      attrs = {}
      attrs[:email] = entry[:mail].first rescue nil
      attrs[:display_name] = entry[:displayname].first rescue nil
      attrs[:address] = entry[:postaladdress].first.gsub('$', "\n") rescue nil
      attrs[:admin_area] = entry[:psadminarea].first rescue nil
      attrs[:department] = entry[:psdepartment].first rescue nil
      attrs[:title] = entry[:title].first rescue nil
      attrs[:office] = entry[:psofficelocation].first.gsub('$', "\n") rescue nil
      attrs[:chat_id] = entry[:pschatname].first rescue nil
      attrs[:website] = entry[:labeleduri].first.gsub('$', "\n") rescue nil
      attrs[:affiliation] = entry[:edupersonprimaryaffiliation].first rescue nil
      attrs[:telephone] = entry[:telephonenumber].first rescue nil
      update_attributes(attrs)

      # update the group cache also
      groups!
    end

    def ldap_exist?
      if (ldap_last_update.blank? || ((Time.now-ldap_last_update) > 24*60*60 ))
        return ldap_exist!
      end
      return ldap_available
    end

    def ldap_exist!
      exist = retry_unless(7.times, lambda { Hydra::LDAP.connection.get_operation_result.code == 53 }) do
        Hydra::LDAP.does_user_exist?(Net::LDAP::Filter.eq('uid', login))
      end rescue false
      if Hydra::LDAP.connection.get_operation_result.code == 0
        logger.debug "exist = #{exist}"
        attrs = {}
        attrs[:ldap_available] = exist
        attrs[:ldap_last_update] = Time.now
        update_attributes(attrs)
        # TODO: Should we retry here if the code is 51-53???
      else
        logger.warn "LDAP error checking exists for #{login}, reason (code: #{Hydra::LDAP.connection.get_operation_result.code}): #{Hydra::LDAP.connection.get_operation_result.message}"
        return false
      end
      return exist
    end

    def directory_attributes(attrs=[])
      UserLdap.directory_attributes(login, attrs)
    end

    # Groups that user is a member of
    def groups
      if (groups_last_update.blank? || ((Time.now-groups_last_update) > 24*60*60 ))
        return groups!
      end
      return self.group_list.split(";?;")
    end

    def groups!
      list = self.class.groups(login)

      if Hydra::LDAP.connection.get_operation_result.code == 0
        list.sort!
        logger.debug "groups = #{list}"
        attrs = {}
        attrs[:ldap_na] = false
        attrs[:group_list] = list.join(";?;")
        attrs[:groups_last_update] = Time.now
        update_attributes(attrs)
        # TODO: Should we retry here if the code is 51-53???
      else
        logger.warn "Error getting groups for #{login} reason: #{Hydra::LDAP.connection.get_operation_result.message}"
        return []
      end
      return list
    end

    module ClassMethods
      def directory_attributes(login, attrs=[])
        attrs = retry_unless(7.times, lambda { Hydra::LDAP.connection.get_operation_result.code == 53 }) do
          Hydra::LDAP.get_user(Net::LDAP::Filter.eq('uid', login), attrs)
        end rescue []
        return attrs
      end

      def groups(login)
        groups = retry_unless(7.times, lambda { Hydra::LDAP.connection.get_operation_result.code == 53 }) do
          Hydra::LDAP.groups_for_user(Net::LDAP::Filter.eq('uid', login)) do |result|
            result.first[:psmemberof].select{ |y| y.starts_with? 'cn=umg/' }.map{ |x| x.sub(/^cn=/, '').sub(/,dc=psu,dc=edu/, '') }
          end rescue []
        end
        return groups
      end
    end

  end

  module Controller
    def has_access?
      unless current_user.ldap_exist?
        render :template => '/error/401', :layout => "error", :formats => [:html], :status => 401
      end
    end
  end
end
