require 'hydra/head'

module CurationConcerns
  extend ActiveSupport::Autoload

  module Models
    module Utils
      extend ActiveSupport::Concern

      def retry_unless(number_of_tries, condition, &block)
        self.class.retry_unless(number_of_tries, condition, &block)
      end

      module ClassMethods
        def retry_unless(number_of_tries, condition, &_block)
          fail ArgumentError, 'First argument must be an enumerator' unless number_of_tries.is_a? Enumerator
          fail ArgumentError, 'Second argument must be a lambda' unless condition.respond_to? :call
          fail ArgumentError, 'Must pass a block of code to retry' unless block_given?
          number_of_tries.each do
            result = yield
            return result unless condition.call
          end
          fail 'retry_unless could not complete successfully. Try upping the # of tries?'
        end
      end
    end
  end

  autoload :Permissions
  autoload :Messages
  autoload :NullLogger
  eager_autoload do
    autoload :Configuration
    autoload :Name
  end

  attr_writer :queue

  def self.queue
    @queue ||= config.queue.new('curation_concerns')
  end
end
