// Attaches a TinyMCE WYSIWYG editor to any textarea that the flexible
// rich-text edit field renders for a `form: { input_type: rich_text }` property.
// The edit field (records/edit_fields/_rich_text) emits
// `<textarea class="rich-text">` (single-valued) or a multi_value widget of such
// textareas with an "Add another" control; this turns each into a
// what-you-see-is-what-you-get editor whose HTML output is stored on the field
// and rendered (sanitized) on the show page by Hyrax::Renderers::HtmlAttributeRenderer.
//
// TinyMCE ships with Hyrax (tinymce-rails), so apps get the editor by default.
// Applications may override this file (or the toolbar/plugins below) to swap in
// a different editor; with no JS at all the field degrades to a plain textarea.
(function () {
  var TOOLBAR = 'undo redo | formatselect | bold italic underline | bullist numlist | blockquote link | removeformat | code';
  var PLUGINS = 'lists link autolink code';
  // Block-format dropdown (formatselect): paragraph plus the heading levels the
  // renderer allows, so editors can apply H1-H4 without typing markup.
  var BLOCK_FORMATS = 'Paragraph=p; Heading 1=h1; Heading 2=h2; Heading 3=h3; Heading 4=h4';
  // Keep stored markup aligned with HtmlAttributeRenderer's allow-list.
  var VALID_ELEMENTS = 'p,br,strong/b,em/i,u,s,a[href|title|target|rel],ul,ol,li,blockquote,h1,h2,h3,h4,h5,h6,code,pre,span';

  function uniqueId() {
    return 'rich-text-' + Date.now() + '-' + Math.floor(Math.random() * 100000);
  }

  function initEditor(textarea) {
    if (typeof tinymce === 'undefined' || !textarea) { return; }
    // TinyMCE keys editors by id; ensure each textarea has a unique, un-bound id.
    if (!textarea.id || tinymce.get(textarea.id)) { textarea.id = uniqueId(); }
    tinymce.init({
      target: textarea,
      menubar: false,
      branding: false,
      plugins: PLUGINS,
      toolbar: TOOLBAR,
      block_formats: BLOCK_FORMATS,
      // Fill the field width; without this TinyMCE uses its default size and looks
      // cramped inside the multi_value widget's input-group wrapper. The companion
      // rule in hyrax/_tinymce.scss handles that wrapper's flex layout.
      width: '100%',
      valid_elements: VALID_ELEMENTS
    });
  }

  function initAll() {
    if (typeof tinymce === 'undefined') { return; }
    var nodes = document.querySelectorAll('textarea.rich-text');
    for (var i = 0; i < nodes.length; i++) {
      if (!tinymce.get(nodes[i].id)) { initEditor(nodes[i]); }
    }
  }

  // When the multi_value "Add another" control clones a field, the clone carries
  // a stale copy of the source editor's TinyMCE DOM. Strip it, then initialize a
  // fresh editor on the cloned textarea.
  function onManagedFieldAdd(_event, added) {
    if (typeof window.jQuery === 'undefined') { return; }
    var $ = window.jQuery;
    // hydra-editor triggers this event *before* it appends the cloned field to
    // the listing, so defer until the node is attached to the DOM. Initializing
    // TinyMCE on a detached node breaks the subsequent append.
    setTimeout(function () {
      var $added = $(added);
      var $textarea = $added.is('textarea.rich-text') ? $added : $added.find('textarea.rich-text');
      if (!$textarea.length) { $textarea = $added.closest('li').find('textarea.rich-text'); }
      if (!$textarea.length) { return; }

      var $li = $textarea.closest('li');
      // Remove any cloned TinyMCE chrome so we can rebind cleanly.
      $li.find('.tox-tinymce, .mce-tinymce').remove();

      var textarea = $textarea[0];
      textarea.style.display = '';
      textarea.removeAttribute('aria-hidden');
      textarea.value = '';
      textarea.id = uniqueId();
      initEditor(textarea);
    }, 0);
  }

  function bind() {
    initAll();
    if (typeof window.jQuery !== 'undefined') {
      // Rebind defensively (off then on) so Turbo re-renders don't stack handlers.
      window.jQuery(document).off('managed_field:add.hyraxRichText')
            .on('managed_field:add.hyraxRichText', onManagedFieldAdd);
    }
  }

  document.addEventListener('DOMContentLoaded', bind);
  document.addEventListener('turbo:load', bind);
  document.addEventListener('turbolinks:load', bind);
}());
