export default class SaveManager {
  constructor() {
    this.override_save_button()
    this.elements = []
  }

  override_save_button() {
    Blacklight.onLoad(() => {
      this.save_button.on('click', this.clicked_save)
    })
  }

  push_changed(element) {
    this.elements.push(element)
    this.elements = $.unique(this.elements)
    this.check_button()
  }

  mark_unchanged(element) {
    this.elements = jQuery.grep(this.elements, (value) => {
      return value != element
    })
    this.check_button()
  }

  check_button() {
    if(this.is_changed && this.save_button.selector.valueOf("data-action") === "*[data-action='save-actions']") {
      this.save_button.removeClass("disabled")
    } else {
      this.save_button.addClass("disabled")
    }
  }

  persist() {
    let promises = []
    this.elements.forEach((element) => {
      let result = element.persist()
      promises.push(
        result.then(() => { return element })
        .done((element) => { this.mark_unchanged(element) })
        .fail((element) => { this.push_changed(element) })
      )
    })
    var label = this.save_button.text()
    this.save_button.text(label + " ...")
    this.save_button.addClass("disabled")
    $.when.apply($, promises).always(() => { this.reset_save_button(label) })
  }
  
  reset_save_button(label) {
    this.save_button.text(label)
    this.check_button()
  }

  get is_changed() {
    return this.elements.length > 0
  }

  get save_button() {
    return $("*[data-action='save-actions']")
  }

  get clicked_save() {
    return (event) => {
      event.preventDefault()
      this.persist()
    }
  }
}
