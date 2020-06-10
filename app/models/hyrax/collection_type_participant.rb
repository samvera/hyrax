# frozen_string_literal: true
module Hyrax
  class CollectionTypeParticipant < ActiveRecord::Base
    self.table_name = 'collection_type_participants'
    belongs_to :hyrax_collection_type, class_name: 'CollectionType'

    MANAGE_ACCESS = 'manage'
    CREATE_ACCESS = 'create'

    GROUP_TYPE = 'group'
    USER_TYPE = 'user'

    validates :agent_id, presence: true
    validates :agent_type, presence: true, inclusion: { in: [GROUP_TYPE, USER_TYPE],
                                                        message: "%<value>s is not a valid agent type.  Accepts: #{GROUP_TYPE}, #{USER_TYPE}" }
    validates :access, presence: true, inclusion: { in: [MANAGE_ACCESS, CREATE_ACCESS],
                                                    message: "%<value>s is not a valid access.  Accepts: #{MANAGE_ACCESS}, #{CREATE_ACCESS}" }
    validates :hyrax_collection_type_id, presence: true

    def manager?
      access == MANAGE_ACCESS
    end

    def creator?
      access == CREATE_ACCESS
    end

    def label
      return agent_id unless agent_type == GROUP_TYPE
      case agent_id
      when ::Ability.registered_group_name
        I18n.t('hyrax.admin.admin_sets.form_participant_table.registered_users')
      when ::Ability.admin_group_name
        I18n.t('hyrax.admin.admin_sets.form_participant_table.admin_users')
      else
        agent_id
      end
    end
  end
end
