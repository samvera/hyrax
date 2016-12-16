class User
  
  include Hydra::User

  attr_accessor :uid

  def initialize(params={})
    self.uid = params.delete(:uid) if params[:uid]
    super
  end
  
end
