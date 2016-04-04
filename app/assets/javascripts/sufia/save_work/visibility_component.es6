export class VisibilityComponent {
  constructor(element) {
    this.element = element
    $('.collapse').collapse({ toggle: false })
    element.find("[type='radio']").on('change', () => { this.showForm() })
    this.showForm()
  }

  showForm() {
    this.collapseAll()
    this.openSelected()
  }

  collapseAll() {
    $('.collapse').collapse('hide');
  }

  openSelected() {
    let selected = this.element.find("[type='radio']:checked")

    let target = selected.data('target')
    if (!target) {
      return
    }
    $(target).collapse('show');
  }
}
