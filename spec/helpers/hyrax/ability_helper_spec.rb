# frozen_string_literal: true
RSpec.describe Hyrax::AbilityHelper do
  describe "#visibility_badge" do
    subject { helper.visibility_badge visibility }

    {
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC =>
        "<span class=\"badge badge-success\">Public</span>",
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED =>
        "<span class=\"badge badge-info\">%<name>s</span>",
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE =>
        "<span class=\"badge badge-danger\">Private</span>",
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO =>
        "<span class=\"badge badge-warning\">Embargo</span>",
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE =>
        "<span class=\"badge badge-warning\">Lease</span>"
    }.each do |value, output|
      context value do
        let(:visibility) { value }

        it { expect(subject).to eql(format(output, name: t('hyrax.institution_name'))) }
      end
    end
  end

  describe "#visibility_options" do
    let(:public_opt) { ['Public', Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC] }
    let(:authenticated_opt) { [t('hyrax.institution_name'), Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED] }
    let(:private_opt) { ['Private', Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE] }

    subject { helper.visibility_options(option) }

    context 'all options' do
      let(:options) { [public_opt, authenticated_opt, private_opt] }
      let(:option) { nil }

      it { is_expected.to eql(options) }
    end
    context 'restricting options' do
      let(:options) { [private_opt, authenticated_opt] }
      let(:option) { :restrict }

      it { is_expected.to eql(options) }
    end
    context 'loosening options' do
      let(:options) { [public_opt, authenticated_opt] }
      let(:option) { :loosen }

      it { is_expected.to eql(options) }
    end
  end

  describe "#render_visibility_link" do
    subject { helper.render_visibility_link(document) }

    context 'admin set' do
      let(:document) { double(admin_set?: true) }

      it { is_expected.to be_nil }
    end
  end
end
