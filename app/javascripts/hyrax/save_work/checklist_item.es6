export class ChecklistItem {
  constructor(element) {
    this.element = element
  }

  check() {
    this.element.removeClass('incomplete')
    this.element.addClass('complete')
  }

  uncheck() {
    this.element.removeClass('complete')
    this.element.addClass('incomplete')
  }
}
