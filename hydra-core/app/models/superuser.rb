# @deprecated - we are moving away from this approach; this code will be removed no later than release 6.x 
# To make a superuser record, look up the ID (not the login) of a previously created user,
# and then insert that id into the superusers table
require 'deprecation'
class Superuser < ActiveRecord::Base
  extend Deprecation
  belongs_to :user
    
  def initialize
    Deprecation.warn(Superuser, "Superuser is deprecated and will be removed from HydraHead in release 5 or 6; we are moving away from this approach.")
    super
  end

end
