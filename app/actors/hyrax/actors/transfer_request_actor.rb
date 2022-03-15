# frozen_string_literal: true
module Hyrax
  module Actors
    # Notify the provided owner that their proxy wants to make a
    # deposit on their behalf
    class TransferRequestActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        next_actor.create(env) && create_proxy_deposit_request(env)
      end

      private

      def create_proxy_deposit_request(env)
        proxy = env.curation_concern.on_behalf_of
        return true if proxy.blank?
        work = env.curation_concern
        user = ::User.find_by_user_key(proxy)
        Hyrax::ChangeContentDepositorService.call(work, user, false)
        ContentDepositorChangeEventJob.perform_later(work)
        true
      end
    end
  end
end
