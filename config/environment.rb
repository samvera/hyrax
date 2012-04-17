# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
ScholarSphere::Application.initialize!

ScholarSphere::Application.configure do
  config.fits_path = 'fits.sh'
  config.max_days_between_audits = 7
  config.id_namespace = Rails.application.class.parent_name.downcase
  config.application_name = Rails.application.class.parent_name
end
