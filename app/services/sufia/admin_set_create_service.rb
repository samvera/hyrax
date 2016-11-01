module Sufia
  # Creates AdminSets
  class AdminSetCreateService
    # @param admin_set [AdminSet] the admin set to operate on
    # @param creating_user [User] the user who created the admin set.
    def initialize(admin_set, creating_user)
      @admin_set = admin_set
      @creating_user = creating_user
    end

    attr_reader :creating_user, :admin_set

    # Creates an admin set, setting the creator and the default access controls.
    # @return [TrueClass, FalseClass] true if it was successful
    def create
      admin_set.read_groups = ['public']
      admin_set.edit_groups = ['admin']
      admin_set.creator = [creating_user.user_key]
      admin_set.save
    end
  end
end
