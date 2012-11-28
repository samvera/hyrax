class User
  
  include Hydra::User

  attr_accessor :uid, :email, :password, :roles, :new_record

  def initialize(params={})
    self.email = params[:email] if params[:email]
    self.uid = params[:uid] if params[:uid]
    self.new_record = params[:new_record] if params[:new_record]
  end
  
  def new_record?
    new_record == true
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
