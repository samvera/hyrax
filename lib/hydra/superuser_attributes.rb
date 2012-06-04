# @deprecated no longer doing permissions this way.  Will be removed no later than release 6.x
require 'deprecation'
module Hydra::SuperuserAttributes
  extend Deprecation

  self.deprecation_horizon = 'hydra-head 5.x'

  def can_be_superuser?
    Superuser.find_by_user_id(self.id) ? true : false
  end

  def is_being_superuser?(session=nil)
    return false if session.nil?
    session[:superuser_mode] ? true : false
  end

  deprecation_deprecate :can_be_superuser?
  deprecation_deprecate :is_being_superuser?

end
