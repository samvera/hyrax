# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Scholarsphere
  module Utils
    extend ActiveSupport::Concern

    def retry_unless(number_of_tries, condition, &block)
      self.class.retry_unless(number_of_tries, condition, &block)
    end

    module ClassMethods
      def retry_unless(number_of_tries, condition, &block)
        raise ArgumentError, "First argument must be an enumerator" unless number_of_tries.is_a? Enumerator
        raise ArgumentError, "Second argument must be a lambda" unless condition.respond_to? :call
        raise ArgumentError, "Must pass a block of code to retry" unless block_given?
        number_of_tries.each do
          result = block.call
          return result unless condition.call
        end
        raise RuntimeError, "retry_unless could not complete successfully. Try upping the # of tries?"
      end
    end
  end
end
