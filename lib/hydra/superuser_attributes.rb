module Hydra::SuperuserAttributes

  def can_be_superuser?
    Superuser.find_by_user_id(self.id) ? true : false
  end

  def is_being_superuser?(session=nil)
    return false if session.nil?
    session[:superuser_mode] ? true : false
  end

end