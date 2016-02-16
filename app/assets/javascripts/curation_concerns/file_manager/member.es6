Blacklight.onLoad(function() {
  $("li[data-reorder-id]").each(function(index, element) {
    let manager_member = new FileManagerMember($(element), window.save_manager)
    $(element).data("file_manager_member", manager_member)
  })
})
class InputTracker {
  constructor(element, notifier) {
    this.element = element
    this.notifier = notifier
    this.element.data("initial-value", this.element.val())
    this.element.data("tracker", this)
    this.element.change(this.value_changed)
  }

  reset() {
    this.element.data("initial-value", this.element.val())
    this.notifier.mark_unchanged(this.element)
  }

  get value_changed() {
    return () => {
      if(this.element.val() == this.element.data("initial-value")) {
        this.notifier.mark_unchanged(this.element)
      } else {
        this.notifier.push_changed(this.element)
      }
    }
  }
}
class FileManagerMember {
  constructor(element, save_manager) {
    this.element = element
    this.save_manager = save_manager
    this.elements = []
    this.track_label()
  }

  push_changed(element) {
    this.elements.push(element)
    this.elements = $.unique(this.elements)
    this.save_manager.push_changed(this)
  }

  mark_unchanged(element) {
    this.elements = jQuery.grep(this.elements, (value) => {
      return value != element
    })
    if(!this.is_changed) {
      this.save_manager.mark_unchanged(this)
    }
  }

  get is_changed() {
    return this.elements.length > 0
  }

  track_label() {
    new InputTracker(this.element.find("input[type='text']"), this)
  }

  persist() {
    if(this.is_changed) {
      let form = this.element.find("form")
      let deferred = $.Deferred()
      form.on("ajax:success", () => {
        this.elements.forEach((element) => {
          element.data("tracker").reset()
        })
        deferred.resolve()
      })
      form.on("ajax:error", () => {
        deferred.reject()
      })
      form.submit()
      return deferred
    } else {
      return $.Deferred().resolve()
    }
  }
}

