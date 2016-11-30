export default class SaveManager {
  constructor() {
    this.override_save_button()
    this.elements = []
  }

  override_save_button() {
    Blacklight.onLoad(() => {
      this.save_button.click(this.clicked_save)
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
    if(this.is_changed && this.save_button.text() == "Save") {
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
    this.save_button.text("Saving...")
    this.save_button.addClass("disabled")
    $.when.apply($, promises).always(() => { this.reset_save_button() })
  }
  
  reset_save_button() {
    this.save_button.text("Save")
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
