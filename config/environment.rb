# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Gamma::Application.initialize!

Gamma::Application.configure do
  config.fits_path = 'fits.sh'
end
