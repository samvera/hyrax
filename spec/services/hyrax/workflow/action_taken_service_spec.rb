# frozen_string_literal: true
RSpec.describe Hyrax::Workflow::ActionTakenService do
  let(:triggered_methods) { [instance_double(Sipity::Method, service_name: 'SpyAction')] }
  let(:triggered_methods_rel) do
    double('Sipity::Method::ActiveRecord_Relation',
           order: triggered_methods,
           any?: true)
  end
  let(:work) { FactoryBot.build(:monograph) }
  let(:action) { instance_double(Sipity::WorkflowAction, triggered_methods: triggered_methods_rel) }
  let(:user) { FactoryBot.create(:user) }
  let(:instance) do
    described_class.new(target: work,
                        action: action,
                        comment: "A pleasant read",
                        user: user)
  end

  describe '.handle_action_token' do
    it { expect(described_class).to respond_to(:handle_action_taken) }
  end

  describe "#call" do
    context "when the method exists" do
      around do |example|
        class SpyAction
          class_attribute :no_op
          class_attribute :fail
          class_attribute :comment
          class_attribute :target
          class_attribute :user

          def self.call(target:, user:, comment:, **)
            target.title = "Spy Action's Choice of Title" unless no_op

            self.target = target
            self.user = user
            self.comment = comment

            !self.fail
          end
        end

        example.run

        Object.send(:remove_const, :SpyAction)
      end

      context "and the method succeedes" do
        it "calls the method and saves the object" do
          expect { instance.call }
            .to change { Hyrax.query_service.count_all_of_model(model: work.class) }
            .by 1

          expect(SpyAction.comment).to eq "A pleasant read"
          expect(SpyAction.user).to eq user
          expect(SpyAction.target.model).to eq work
        end
      end

      context "and the method fails" do
        before { SpyAction.fail = true }

        it "calls the method and does not save the object" do
          expect(Hyrax.logger)
            .to receive(:error)
            .with("Not all workflow methods were successful, so not saving (#{work.id})")

          expect { instance.call }
            .not_to change { Hyrax.query_service.count_all_of_model(model: work.class) }

          expect(SpyAction.comment).to eq "A pleasant read"
          expect(SpyAction.user).to eq user
          expect(SpyAction.target.model).to eq work
        end
      end

      context "and no changes are made" do
        before { SpyAction.no_op = true }

        it "calls the method and does not save the object" do
          expect { instance.call }
            .not_to change { Hyrax.query_service.count_all_of_model(model: work.class) }

          expect(SpyAction.comment).to eq "A pleasant read"
          expect(SpyAction.user).to eq user
          expect(SpyAction.target.model).to eq work
        end
      end
    end

    context "when the notification class doesn't have the method" do
      around do |example|
        class SpyAction; end
        example.run
        Object.send(:remove_const, :SpyAction)
      end

      it "logs an error" do
        expect(Hyrax.logger)
          .to receive(:error)
          .with("Expected 'SpyAction' to respond to 'call', but it didn't, so not running workflow callback")
        expect(Hyrax.logger)
          .to receive(:error)
          .with("Not all workflow methods were successful, so not saving (#{work.id})")

        instance.call
      end
    end

    context "when the notification doesn't exist" do
      it "logs an error" do
        expect(Hyrax.logger)
          .to receive(:error)
          .with("Unable to find 'SpyAction', so not running workflow callback")
        expect(Hyrax.logger)
          .to receive(:error)
          .with("Not all workflow methods were successful, so not saving (#{work.id})")

        instance.call
      end
    end
  end
end
