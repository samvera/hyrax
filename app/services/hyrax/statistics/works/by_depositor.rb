module Hyrax
  module Statistics
    module Works
      class ByDepositor < Statistics::TermQuery
        private

          def index_key
            DepositSearchBuilder.depositor_field
          end
      end
    end
  end
end
