# frozen_string_literal: true
module Hyrax
  module Transactions
    module Steps
      class SaveWork
        include Dry::Transaction::Operation

        def call(work)
          work.save ? Success(work) : Failure(:not_saved)
        end
      end
    end
  end
end
