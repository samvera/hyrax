require 'spec_helper'

RSpec.describe CurationConcerns::Workflow::ActionTakenService do
  context 'class methods' do
    subject { described_class }
    it { is_expected.to respond_to(:handle_action_taken) }
  end

  let(:triggered_methods) { [instance_double(Sipity::Method, service_name: 'foo_bar')] }
  let(:triggered_methods_rel) do
    instance_double(Sipity::Method::ActiveRecord_Relation,
                    order: triggered_methods,
                    any?: true)
  end
  let(:work) { instance_double(GenericWork) }
  let(:action) { instance_double(Sipity::WorkflowAction, triggered_methods: triggered_methods_rel) }
  let(:entity) { instance_double(Sipity::Entity, id: 9999, proxy_for: work) }
  let(:user) { User.new }
  let(:instance) do
    described_class.new(entity: entity,
                        action: action,
                        comment: "A pleasant read",
                        user: user)
  end

  describe "#call" do
    subject { instance.call }
    context "when the method exists" do
      around do |example|
        class FooBar
          def self.call
          end
        end
        example.run
        Object.send(:remove_const, :FooBar)
      end

      context "and the method succeedes" do
        it "calls the method and saves the object" do
          expect(work).to receive(:save)
          expect(FooBar).to receive(:call).with(entity: entity, user: user, comment: "A pleasant read").and_return(true)
          subject
        end
      end
      context "and the method fails" do
        it "calls the method and saves the object" do
          expect(work).not_to receive(:save)
          expect(FooBar).to receive(:call).with(entity: entity, user: user, comment: "A pleasant read").and_return(false)
          expect(Rails.logger).to receive(:error).with("Not all workflow methods were successful, so not saving (9999)")
          subject
        end
      end
    end

    context "when the notification class doesn't have the method" do
      around do |example|
        class FooBar; end
        example.run
        Object.send(:remove_const, :FooBar)
      end
      it "logs an error" do
        expect(Rails.logger).to receive(:error).with("Expected 'FooBar' to respond to 'call', but it didn't, so not running workflow callback")
        expect(Rails.logger).to receive(:error).with("Not all workflow methods were successful, so not saving (9999)")
        subject
      end
    end

    context "when the notification doesn't exist" do
      it "logs an error" do
        expect(Rails.logger).to receive(:error).with("Unable to find 'FooBar', so not running workflow callback")
        expect(Rails.logger).to receive(:error).with("Not all workflow methods were successful, so not saving (9999)")
        subject
      end
    end
  end
end
