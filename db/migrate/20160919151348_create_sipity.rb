class CreateSipity < ActiveRecord::Migration[5.0]
  def change
    create_table "sipity_notification_recipients" do |t|
      t.integer  "notification_id",                null: false
      t.integer  "role_id",                        null: false
      t.string   "recipient_strategy",             null: false
      t.datetime "created_at",                     null: false
      t.datetime "updated_at",                     null: false
    end

    add_index "sipity_notification_recipients", ["notification_id", "role_id", "recipient_strategy"], name: "sipity_notifications_recipients_surrogate"
    add_index "sipity_notification_recipients", ["notification_id"], name: "sipity_notification_email_recipients_email"
    add_index "sipity_notification_recipients", ["recipient_strategy"], name: "sipity_notification_email_recipients_recipient_strategy"
    add_index "sipity_notification_recipients", ["role_id"], name: "sipity_notification_email_recipients_role"

    create_table "sipity_notifications" do |t|
      t.string   "name",             null: false
      t.datetime "created_at",              null: false
      t.datetime "updated_at",              null: false
    end

    add_index "sipity_notifications", ["name"], name: "index_sipity_notifications_on_name"

    create_table "sipity_notification_notifiable_contexts" do |t|
      t.integer  "scope_for_notification_id",               null: false
      t.string   "scope_for_notification_type",             null: false
      t.string   "reason_for_notification",                 null: false
      t.integer  "notification_id",                         null: false
      t.datetime "created_at",                              null: false
      t.datetime "updated_at",                              null: false
    end

    add_index "sipity_notification_notifiable_contexts", ["notification_id"], name: "sipity_notification_notifiable_contexts_notification_id"
    add_index "sipity_notification_notifiable_contexts", ["scope_for_notification_id", "scope_for_notification_type", "reason_for_notification", "notification_id"], name: "sipity_notification_notifiable_contexts_concern_surrogate", unique: true
    add_index "sipity_notification_notifiable_contexts", ["scope_for_notification_id", "scope_for_notification_type", "reason_for_notification"], name: "sipity_notification_notifiable_contexts_concern_context"
    add_index "sipity_notification_notifiable_contexts", ["scope_for_notification_id", "scope_for_notification_type"], name: "sipity_notification_notifiable_contexts_concern"

    create_table "sipity_agents" do |t|
      t.string   "proxy_for_id",               null: false
      t.string   "proxy_for_type",             null: false
      t.datetime "created_at",                 null: false
      t.datetime "updated_at",                 null: false
    end

    add_index "sipity_agents", ["proxy_for_id", "proxy_for_type"], name: "sipity_agents_proxy_for", unique: true

    create_table "sipity_comments" do |t|
      t.integer  "entity_id",                                                    null: false
      t.integer  "agent_id",                                                     null: false
      t.text     "comment"
      t.integer  "originating_strategy_action_id",                               null: false
      t.integer  "originating_strategy_state_id",                                null: false 
      t.datetime "created_at",                                                   null: false
      t.datetime "updated_at",                                                   null: false
      t.boolean  "stale",                                        default: false
    end

    add_index "sipity_comments", ["agent_id"], name: "index_sipity_comments_on_agent_id"
    add_index "sipity_comments", ["created_at"], name: "index_sipity_comments_on_created_at"
    add_index "sipity_comments", ["entity_id"], name: "index_sipity_comments_on_entity_id"
    add_index "sipity_comments", ["originating_strategy_action_id"], name: "sipity_comments_action_index"
    add_index "sipity_comments", ["originating_strategy_state_id"], name: "sipity_comments_state_index"

    create_table "sipity_entities" do |t|
      t.string   "proxy_for_id",                  null: false
      t.string   "proxy_for_type",                null: false
      t.integer  "strategy_id",                   null: false
      t.integer  "strategy_state_id",             null: false
      t.datetime "created_at",                    null: false
      t.datetime "updated_at",                    null: false
    end

    add_index "sipity_entities", ["proxy_for_id", "proxy_for_type"], name: "sipity_entities_proxy_for", unique: true
    add_index "sipity_entities", ["strategy_id"], name: "index_sipity_entities_on_strategy_id"
    add_index "sipity_entities", ["strategy_state_id"], name: "index_sipity_entities_on_strategy_state_id"

    create_table "sipity_entity_specific_responsibilities" do |t|
      t.integer  "strategy_role_id",            null: false
      t.string   "entity_id",                   null: false
      t.integer  "agent_id",                    null: false
      t.datetime "created_at",                  null: false
      t.datetime "updated_at",                  null: false
    end

    add_index "sipity_entity_specific_responsibilities", ["agent_id"], name: "sipity_entity_specific_responsibilities_agent"
    add_index "sipity_entity_specific_responsibilities", ["entity_id"], name: "sipity_entity_specific_responsibilities_entity"
    add_index "sipity_entity_specific_responsibilities", ["strategy_role_id", "entity_id", "agent_id"], name: "sipity_entity_specific_responsibilities_aggregate", unique: true
    add_index "sipity_entity_specific_responsibilities", ["strategy_role_id"], name: "sipity_entity_specific_responsibilities_role"

    create_table "sipity_strategies" do |t|
      t.string   "name",                      null: false
      t.text     "description"
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
    end

    add_index "sipity_strategies", ["name"], name: "index_sipity_strategies_on_name", unique: true

    create_table "sipity_strategy_actions" do |t|
      t.integer  "strategy_id",                                                  null: false
      t.integer  "resulting_strategy_state_id"
      t.string   "name",                                                         null: false
      t.datetime "created_at",                                                   null: false
      t.datetime "updated_at",                                                   null: false
    end

    add_index "sipity_strategy_actions", ["resulting_strategy_state_id"], name: "sipity_strategy_actions_resulting_strategy_state"
    add_index "sipity_strategy_actions", ["strategy_id", "name"], name: "sipity_strategy_actions_aggregate", unique: true
    add_index "sipity_strategy_actions", ["strategy_id"], name: "sipity_strategy_actions_strategy"

    create_table "sipity_strategy_responsibilities" do |t|
      t.integer  "agent_id",                   null: false
      t.integer  "strategy_role_id",           null: false
      t.datetime "created_at",                 null: false
      t.datetime "updated_at",                 null: false
    end

    add_index "sipity_strategy_responsibilities", ["agent_id", "strategy_role_id"], name: "sipity_strategy_responsibilities_aggregate", unique: true

    create_table "sipity_strategy_roles" do |t|
      t.integer  "strategy_id",           null: false
      t.integer  "role_id",               null: false
      t.datetime "created_at",            null: false
      t.datetime "updated_at",            null: false
    end

    add_index "sipity_strategy_roles", ["strategy_id", "role_id"], name: "sipity_strategy_roles_aggregate", unique: true

    create_table "sipity_strategy_state_action_permissions" do |t|
      t.integer  "strategy_role_id",                   null: false
      t.integer  "strategy_state_action_id",           null: false
      t.datetime "created_at",                         null: false
      t.datetime "updated_at",                         null: false
    end

    add_index "sipity_strategy_state_action_permissions", ["strategy_role_id", "strategy_state_action_id"], name: "sipity_strategy_state_action_permissions_aggregate", unique: true

    create_table "sipity_strategy_state_actions" do |t|
      t.integer  "originating_strategy_state_id",           null: false
      t.integer  "strategy_action_id",                      null: false
      t.datetime "created_at",                              null: false
      t.datetime "updated_at",                              null: false
    end

    add_index "sipity_strategy_state_actions", ["originating_strategy_state_id", "strategy_action_id"], name: "sipity_strategy_state_actions_aggregate", unique: true

    create_table "sipity_strategy_states" do |t|
      t.integer  "strategy_id",             null: false
      t.string   "name",                    null: false
      t.datetime "created_at",              null: false
      t.datetime "updated_at",              null: false
    end

    add_index "sipity_strategy_states", ["name"], name: "index_sipity_strategy_states_on_name"
    add_index "sipity_strategy_states", ["strategy_id", "name"], name: "sipity_type_state_aggregate", unique: true

    create_table "sipity_roles" do |t|
      t.string   "name",                      null: false
      t.text     "description"
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
    end

    add_index "sipity_roles", ["name"], name: "index_sipity_roles_on_name", unique: true
  end
end
