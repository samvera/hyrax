# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::WorksSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability,
           current_user: user)
  end
  let(:ability) do
    ::Ability.new(user)
  end
  let(:user) { create(:user, groups: 'registered') }
  let(:builder) { described_class.new(context) }

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }

    it { is_expected.to include :show_only_managed_works_for_non_admins }
  end

  describe '#discovery_permissions' do
    subject { builder.discovery_permissions }

    it { is_expected.to eq %w[edit read] }
  end

  describe "#show_only_managed_works_for_non_admins" do
    let(:solr_params) { Blacklight::Solr::Request.new }

    before do
      builder.show_only_managed_works_for_non_admins(solr_params)
    end

    it "has filter that excludes depositor" do
      expect(solr_params[:fq]).to eq ["-_query_:\"{!raw f=depositor_ssim}#{user.user_key}\""]
    end

    context "as admin" do
      # Overrides the user sent to builder via context, above.
      let(:user) { create(:user, groups: 'admin') }

      it "does nothing" do
        expect(solr_params[:fq].to_a).to eq []
      end
    end
  end

  describe "#apply_group_permissions" do
    subject { builder.apply_group_permissions(permission_types, ability) }
    let(:permission_types) { ["edit", "read"] }

    context 'default user' do
      it "creates expected search term" do
        expect(subject).to eq ["({!terms f=edit_access_group_ssim}public,registered)"]
      end
    end

    context 'as admin' do
      let(:user) { create(:user, groups: 'admin') }
      it "creates expected search term" do
        expect(subject).to eq ["({!terms f=edit_access_group_ssim}public,admin,registered)",
                               "({!terms f=read_access_group_ssim}admin)"]
      end
    end

    context 'user with managing role' do
      let(:role) { Sipity::Role.find_or_create_by(name: Hyrax::RoleRegistry::MANAGING) }
      let(:agent) { Sipity::Agent(user) }
      let(:one_step_workflow) do
        {
          workflows: [
            {
              name: "one_step",
              label: "One-step mediated deposit workflow",
              description: "A single-step workflow for mediated deposit",
              actions: [
                {
                  name: "deposit",
                  from_states: [],
                  transition_to: "pending_review"
                },
                {
                  name: "approve",
                  from_states: [
                    {
                      names: ["pending_review"],
                      roles: ["approving"]
                    }
                  ],
                  transition_to: "deposited",
                  methods: [
                    "Hyrax::Workflow::ActivateObject"
                  ]
                }
              ]
            }
          ]
        }
      end
      let(:permission_template) { create(:permission_template) }

      before do
        Hyrax::Workflow::WorkflowImporter.generate_from_hash(data: one_step_workflow.as_json,
                                                             permission_template: permission_template)
        Hyrax::Workflow::PermissionGenerator.call(roles: [role],
                                                  workflow: Sipity::Workflow.last,
                                                  agents: user)
      end

      it "creates expected search term" do
        expect(subject).to eq ["isPartOf_ssim:#{permission_template.source_id}",
                               "({!terms f=edit_access_group_ssim}public,registered)"]
      end
    end
  end
end
