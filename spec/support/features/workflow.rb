# frozen_string_literal: true
def ensure_deposit_available_for(user)
  template = create(:permission_template, with_admin_set: true, with_workflows: true)
  # Grant the user access to deposit into an admin set.
  create(:permission_template_access,
         :deposit,
         permission_template: template,
         agent_type: 'user',
         agent_id: user.user_key)
end
