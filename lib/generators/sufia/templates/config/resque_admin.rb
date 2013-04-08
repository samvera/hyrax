module Sufia
  class ResqueAdmin
    def self.matches?(request)
      current_user = request.env['warden'].user
      return false if current_user.blank?
      # TODO code a group here that makes sense
      #current_user.groups.include? 'umg/up.dlt.scholarsphere-admin'
    end
  end
end
