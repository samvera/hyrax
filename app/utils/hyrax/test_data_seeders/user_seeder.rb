# frozen_string_literal: true
module Hyrax
  module TestDataSeeders
    # This class was created for use in rake tasks and db/seeds.rb.  It generates
    # users that can be used in release testing.  This data can also be helpful
    # for local development testing.
    #
    # Adding users is non-destructive.  If a user with the email already exists,
    # they will not be replaced.
    class UserSeeder
      class << self
        attr_accessor :logger

        def generate_seeds(logger: Logger.new(STDOUT), allow_seeding_in_production: false)
          raise("TestDataSeeders are not for use in production!") if Rails.env.production? && !allow_seeding_in_production
          @logger = logger

          logger.info("Adding users...")

          add_user('admin@example.com', 'admin_password', admin_role)
          add_user('basic_user@example.com', 'password')
          add_user('another_user@example.com', 'password')
        end

        private

        def admin_role
          unless ::User.reflect_on_association(:roles)
            logger.warn("Cannot create `Role` because the `hyrda-role-management` gem, or " \
                        "other gem providing a definition for a Role class, is not installed.  " \
                        "For development, you can edit `config/role_map.yml` and add the user's " \
                        "email under the role you want to assign.")
            return
          end
          @admin_role ||= Role.find_or_create_by(name: Hyrax.config.admin_user_group_name)
        end

        def add_user(email, password, role = nil)
          created = false
          user = ::User.find_or_create_by(email: email) do |f|
            created = true
            f.password = password
          end
          logger.info("   #{email} -- #{created ? 'CREATED' : 'ALREADY EXISTS'}")
          return unless role && !user.roles.include?(role)
          logger.info("Adding #{role.name} to #{user.email}")
          user.roles << role
          user.save
        end
      end
    end
  end
end
