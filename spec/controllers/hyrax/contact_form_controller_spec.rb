# frozen_string_literal: true
RSpec.describe Hyrax::ContactFormController do
  let(:user) { create(:user) }
  let(:required_params) do
    {
      category: "Depositing content",
      name: "Rose Tyler",
      email: "rose@timetraveler.org",
      subject: "The Doctor",
      message: "Run."
    }
  end

  before { sign_in(user) }

  describe '.model_class' do
    let(:fake_contact_form_class) { Class.new(Hyrax::ContactForm) }

    it 'is Hyrax::ContactForm by default' do
      expect(described_class.model_class).to eq Hyrax::ContactForm
    end

    it 'builds an instance of the class for assigns' do
      allow(described_class).to receive(:model_class).and_return(fake_contact_form_class)

      get :new

      expect(assigns[:contact_form]).to be_a fake_contact_form_class
    end
  end

  describe "#new" do
    subject { response }

    before { get :new }
    it { is_expected.to be_successful }
  end

  describe "#create" do
    subject { flash }

    before { post :create, params: { contact_form: params } }
    context "with the required parameters" do
      let(:params) { required_params }

      its(:notice) { is_expected.to eq("Thank you for your message!") }
    end

    context "without a category" do
      let(:params)  { required_params.except(:category) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Category can't be blank") }
    end

    context "without a name" do
      let(:params)  { required_params.except(:name) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Name can't be blank") }
    end

    context "without an email" do
      let(:params)  { required_params.except(:email) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Email can't be blank") }
    end

    context "without a subject" do
      let(:params)  { required_params.except(:subject) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Subject can't be blank") }
    end

    context "without a message" do
      let(:params)  { required_params.except(:message) }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Message can't be blank") }
    end

    context "with an invalid email" do
      let(:params)  { required_params.merge(email: "bad-wolf") }

      its([:error]) { is_expected.to eq("Sorry, this message was not sent successfully. Email is invalid") }
    end
  end

  describe "#after_deliver" do
    context "with a successful email" do
      it "calls #after_deliver" do
        expect(controller).to receive(:after_deliver)
        post :create, params: { contact_form: required_params }
      end
    end
    context "with an unsuccessful email" do
      it "does not call #after_deliver" do
        expect(controller).not_to receive(:after_deliver)
        post :create, params: { contact_form: required_params.except(:email) }
      end
    end
  end

  context "when encoutering a RuntimeError" do
    let(:logger) { double(info?: true) }

    before do
      allow(controller).to receive(:logger).and_return(logger)
      allow(Hyrax::ContactMailer).to receive(:contact).and_raise(RuntimeError)
    end
    it "is logged via Rails" do
      expect(logger).to receive(:error).with("Contact form failed to send: #<RuntimeError: RuntimeError>")
      post :create, params: { contact_form: required_params }
    end
  end
end
