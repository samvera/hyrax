export default class Notification {
  /**
   * Initializes the notification widget on the page and allows
   * updating of the notification count and notification label
   *
   * @param {jQuery} element the notification widget
   */
  constructor(element) {
    this.element = element
    this.counter = element.find('.count')
  }

  update(count, label) {
    this.element.attr('aria-label', label)
    this.counter.html(count)

    if (count === 0) {
      this.counter.addClass('invisible')
    }
    else {
      this.counter.removeClass('invisible')
      this.counter.addClass('badge-danger').removeClass('badge-secondary')
    }
  }
}
