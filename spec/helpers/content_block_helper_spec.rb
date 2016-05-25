describe ContentBlockHelper, type: :helper do
  let(:content_block) { FactoryGirl.create(:content_block, value: "<p>foo bar</p>") }

  subject { helper.editable_content_block(content_block) }

  context "for someone" do
    context "with access" do
      before do
        expect(helper).to receive(:can?).with(:update, content_block).and_return(true)
      end
      let(:node) { Capybara::Node::Simple.new(subject) }

      it "shows the preview and the form" do
        expect(node).to have_selector "button[data-target='#edit_content_block_1'][data-behavior='reveal-editor']"
        expect(node).to have_selector "form#edit_content_block_1[action='#{sufia.content_block_path(content_block)}']"
        expect(subject).to be_html_safe
      end

      context "with option to create new:" do
        subject { helper.editable_content_block(content_block, true) }

        it "shows the button & form for a new content block" do
          expect(node).to have_selector "button[data-target='#new_content_block'][data-behavior='reveal-editor']"
          expect(node).to have_selector "form#new_content_block[action='#{sufia.content_blocks_path}']"
        end
      end
    end
  end

  context "anonymous" do
    before do
      expect(helper).to receive(:can?).with(:update, content_block).and_return(false)
    end
    it "shows the content" do
      expect(subject).to eq '<p>foo bar</p>'
      expect(subject).to be_html_safe
    end
  end

  describe '#display_editable_content_block?' do
    context 'anonymous' do
      before do
        allow(helper).to receive(:can?).with(:update, content_block).and_return(false)
      end

      it 'is true if the content block has data' do
        expect(helper.display_editable_content_block?(content_block)).to eq true
      end

      it 'is false if the content block is empty data' do
        content_block.update(value: '')
        expect(helper.display_editable_content_block?(content_block)).to eq false
      end
    end

    context 'for someone with access' do
      before do
        allow(helper).to receive(:can?).with(:update, content_block).and_return(true)
      end

      it 'is true if the user can edit the field' do
        content_block.update(value: '')
        expect(helper.display_editable_content_block?(content_block)).to eq true
      end
    end
  end
end
