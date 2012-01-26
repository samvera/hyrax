# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Hylion::Application.initialize!

Hylion::Application.configure do
  config.fits_path = 'fits.sh'
end
