class ResqueAdmin
  def self.matches?(request)
    current_user = request.env['warden'].user
    puts "----------------------------------"
    puts current_user
    puts "----------------------------------"
    return false if current_user.blank?
    puts current_user.groups
    puts "----------------------------------"
    #current_user.groups.include? 'umg/up.dlt.scholarsphere-admin'
    #current_user.groups.include? 'umg/up.its.voipusers'
    return true
  end
end
