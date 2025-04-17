class User < ApplicationRecord
  # Connects this user object to Hydra behaviors.
  include Hydra::User

  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles

  # Connects this user object to Hyrax behaviors.
  include Hyrax::User
  include Hyrax::UserUsageStats

  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  # Groups include roles and those set by #groups= (especially in specs)
  def groups
    g = roles.map(&:name)
    g += group_service.fetch_groups(user: self)
    g
  end
end
