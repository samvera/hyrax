# There is an interplay between an AdminSet and a PermissionTemplate.
# @see Hyrax::AdminSetBehavior for further discussion
class AdminSet < ActiveFedora::Base
  include Hyrax::AdminSetBehavior
end
