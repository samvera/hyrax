require 'curation_concerns/models/version'
require 'curation_concerns/models/engine'

require 'hydra/head'
module CurationConcerns
  extend ActiveSupport::Autoload

  module Models
  end

  autoload :Utils, 'curation_concerns/models/utils'
  autoload :Permissions
  autoload :Messages
  eager_autoload do
    autoload :Configuration
    autoload :Name
  end

  attr_writer :queue

  def self.queue
    @queue ||= config.queue.new('curation_concerns')
  end
end
