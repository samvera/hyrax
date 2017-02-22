require 'spec_helper'

RSpec.describe Hyrax::MenuPresenter do
  let(:instance) { described_class.new(context) }
  let(:context) { ActionView::TestCase::TestController.new.view_context }
  let(:controller_name) { controller.controller_name }

  describe "#workflows_section?" do
    before do
      allow(context).to receive(:controller_name).and_return(controller_name)
      allow(context).to receive(:controller).and_return(controller)
    end
    subject { instance.workflows_section? }

    context "for the WorkflowRolesController" do
      let(:controller) { Hyrax::Admin::WorkflowRolesController.new }
      it { is_expected.to be true }
    end
  end

  describe "#collapsable_section" do
    subject do
      instance.collapsable_section('link title',
                                   id: 'mySection',
                                   icon_class: 'fa fa-cog',
                                   open: open) do
                                     "Some content"
                                   end
    end

    let(:rendered) { Capybara::Node::Simple.new(subject) }
    context "when collapsed" do
      let(:open) { false }
      it "draws a collapsable section" do
        expect(rendered).to have_content "Some content"
        expect(rendered).to have_selector "span.fa.fa-cog"
        expect(rendered).to have_selector "a.collapsed.collapse-toggle[href='#mySection']"
        expect(rendered).to have_selector "ul#mySection"
      end
    end

    context "when open" do
      let(:open) { true }
      it "draws a collapsable section" do
        expect(rendered).to have_content "Some content"
        expect(rendered).to have_selector "span.fa.fa-cog"
        expect(rendered).to have_selector "a.collapse-toggle[href='#mySection']"
        expect(rendered).to have_selector "ul#mySection.in"
      end
    end
  end
end
