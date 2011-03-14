# To make a superuser record, look up the ID (not the login) of a previously created user,
# and then insert that id into the superusers table
class Superuser < ActiveRecord::Base
  belongs_to :user
    
end