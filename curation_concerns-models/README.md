# CurationConcerns::Models

Models extracted from worthwhile-models and sufia-models.

## Dependencies

### FITS 0.6.2

To install FITS:
 * Go to http://projects.iq.harvard.edu/fits/downloads, download __fits-0.6.2.zip__, and unpack it somewhere on your machine. You can also install FITS on OSX with homebrew: `brew install fits` (you may also have to create a symlink from fits.sh -> fits in the next step).
 * Mark fits.sh as executable (chmod a+x fits.sh)
 * Run "fits.sh -h" from the command line and see a help message to ensure FITS is properly installed
 * Give your app access to FITS by:
     * Adding the full fits.sh path to your PATH (e.g., in your .bash_profile), OR
     * Changing config/initializers/sufia.rb to point to your FITS location: config.fits_path = "/<your full path>/fits.sh"



## Installation

Add this line to your application's Gemfile:

    gem 'curation_concerns-models'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install curation_concerns-models

## Usage


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
