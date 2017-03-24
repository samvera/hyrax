// This is the notification widget on the page

export default class {
  constructor(dom_obj) {
    this.dom_obj = dom_obj;
    this.counter = dom_obj.find('.count');
  }

  setCount(count) {
    this.counter.html(count);
    if (count == 0) {
      this.noNotifications()
    } else {
      this.hasNotifications(count)
    }
  }

  // set the styles for no unread notifications
  noNotifications () {
      this.counter.addClass('invisible')
      this.dom_obj.prop('aria-label', this.notificationsLabel(0))
  }

  // set the styles for having unread notifications
  hasNotifications (size) {
    this.counter.removeClass('invisible')
    this.dom_obj.prop('aria-label', this.notificationsLabel(size))
  }

  notificationsLabel(size) {
    if (size == 0)
      return "You have no unread notifications"
    if (size == 1)
      return "You have one unread notification"
    return `You have %{size} unread notifications`
  }
}
