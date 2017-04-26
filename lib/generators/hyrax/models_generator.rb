class Hyrax::ModelsGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :model_name, type: :string, default: 'user'
  desc '
This generator makes the following changes to your application:
 1. Injects the user behavior onto the user models.
 2. Creates the file_set.rb and collection.rb models.
 3. Generates the clam anti-virus configuration.
       '
  def banner
    say_status('info', 'GENERATING HYRAX MODELS', :blue)
  end

  # Setup the database migrations
  def copy_migrations
    rake 'hyrax:install:migrations'
  end

  # Add behaviors to the user model
  def inject_user_behavior
    file_path = "app/models/#{model_name.underscore}.rb"
    if File.exist?(file_path)
      inject_into_file file_path, after: /include Hydra\:\:User.*$/ do
        "\n  # Connects this user object to Hyrax behaviors." \
        "\n  include Hyrax::User" \
        "\n  include Hyrax::UserUsageStats\n"
      end
    else
      puts "     \e[31mFailure\e[0m  Hyrax requires a user object. This " \
           "generator assumes that the model is defined in the file " \
           "#{file_path}, which does not exist.  If you used a different " \
           "name, please re-run the generator and provide that name as an " \
           "argument. Such as \b  rails -g hyrax:models client"
    end
  end

  def create_collection
    copy_file 'app/models/collection.rb', 'app/models/collection.rb'
    copy_file 'spec/models/collection_spec.rb', 'spec/models/collection_spec.rb' if rspec_installed?
  end

  def create_file_set
    copy_file 'app/models/file_set.rb', 'app/models/file_set.rb'
    copy_file 'spec/models/file_set_spec.rb', 'spec/models/file_set_spec.rb' if rspec_installed?
  end

  # Adds clamav initializtion
  def clamav
    generate 'hyrax:clamav'
  end

  private

    def rspec_installed?
      defined?(RSpec) && defined?(RSpec::Rails)
    end
end
