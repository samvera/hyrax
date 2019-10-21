class TabbedForm {
  /**
   * Bootstrap Tabs use anchors to identify tabs. Anchor of active tab is added as hidden input to given form 
   * so that active tab state can be maintained after Post.
   * @param {form} form element that includes tabs and to which tab anchor will be added as an input
   */
  constructor(form) {
    this.form = form;
  }

  setup() {
    this.refererAnchor = this.addRefererAnchor()
    this.watchActiveTab()
    this.setRefererAnchor($('.nav-tabs li.active a').attr('href'))
  }

  addRefererAnchor() {
    let referer_anchor_input = $('<input>').attr({type: 'hidden', id: 'referer_anchor', name: 'referer_anchor'}) 
    this.form.append(referer_anchor_input)
    return referer_anchor_input
  }

  setRefererAnchor(id) {
    this.refererAnchor.val(id)
  }

  watchActiveTab() {
    $('.nav-tabs a').on('shown.bs.tab', (e) => this.setRefererAnchor($(e.target).attr('href')))
  }
}

export default function tabifyForm(form) {
  let formTabifier = new TabbedForm(form)
  formTabifier.setup()
}
