# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Adds and removes work members
      class UpdateWorkMembers
        include Dry::Monads[:result]

        ##
        # @param [Hyrax::Work] obj
        # @param [Hash] work_members_attributes
        #
        # @return [Dry::Monads::Result]
        def call(obj, work_members_attributes: nil, user: nil)
          return Success(obj) if work_members_attributes.blank?

          attributes = extract_attributes(work_members_attributes)
          current_member_ids = obj.member_ids.map(&:id)
          destroys = attributes.select do |v|
            ActiveModel::Type::Boolean.new.cast(v['_destroy'])
          end

          inserts  = (attributes - destroys).map { |h| h['id'] }.compact - current_member_ids
          destroys = destroys.map { |h| h['id'] }.compact & current_member_ids
          obj.member_ids += inserts.map  { |id| Valkyrie::ID.new(id) }
          obj.member_ids -= destroys.map { |id| Valkyrie::ID.new(id) }

          save_resource(obj, user)
          Hyrax.publisher.publish('object.membership.updated', object: obj, user: user)

          Success(obj)
        end

        private

        def extract_attributes(attribute_hash)
          attribute_hash
            .sort_by { |i, _| i.to_i }
            .map { |_, attributes| attributes }
        end

        def save_resource(obj, user)
          saved = Hyrax.persister.save(resource: obj)
          user ||= ::User.find_by_user_key(obj.depositor)
          Hyrax.publisher.publish('object.metadata.updated', object: saved, user: user)
        end
      end
    end
  end
end
