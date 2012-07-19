module ScholarSphere::LDAP
  include Hydra::LDAP
  def self.filter_groups_for_user(uid)
    # Northwestern return Net::LDAP::Filter.construct("(&(objectClass=groupofnames)(member=uid=#{uid}))")
    return Net::LDAP::Filter.eq('uid', uid)
  end 

  def self.result_groups_for_user(result)
    # Northwestern - result.map{|r| r[:cn].first}
    # only get umg and strip off the cn and the ,dc=psu,dc=edu
    return result.blank? ? [] : result.first[:psmemberof].select{ |y| y.starts_with? 'cn=umg/' }.map{ |x| x.sub(/^cn=/, '').sub(/,dc=psu,dc=edu/, '') } 
  end 
end
