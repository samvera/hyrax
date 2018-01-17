module Hyrax
  module Actors
    # Notify the provided owner that their proxy wants to make a
    # deposit on their behalf
    class TransferRequestActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Valkyrie::Resource,FalseClass] the saved resource if create was successful
      def create(env)
        created = next_actor.create(env)
        return created if created && create_proxy_deposit_request(created)
        false
      end

      private

        def create_proxy_deposit_request(work)
          proxy = work.on_behalf_of
          return true if proxy.blank?
          ContentDepositorChangeEventJob.perform_later(work,
                                                       ::User.find_by_user_key(proxy))
          true
        end
    end
  end
end
