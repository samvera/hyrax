class User
  
  include Hydra::User

  attr_accessor :uid, :email, :password, :roles, :new_record

  def initialize(params={})
    self.email = params[:email] if params[:email]
  end
  
  def new_record?
    new_record == true
  end
  
  def is_being_superuser?(session)
    # do nothing -- stubbing deprecated behavior
  end
  
  def self.find_by_uid(uid)
    nil
  end
  
  def save
    # do nothing!
  end
  
  def save!
    save
    return self
  end
  
end
