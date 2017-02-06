export default class SortManager {
  constructor(save_manager) {
    this.element = $("#sortable")
    this.sorting_info = {}
    this.initialize_sort()
    this.element.data("current-order", this.order)
    this.save_manager = save_manager
    this.initialize_alpha_sort_button()
  }

  initialize_sort() {
    this.element.sortable({handle: ".panel-heading"})
    this.element.on("sortstop", this.stopped_sorting)
    this.element.on("sortstart", this.started_sorting)
  }

  persist() {
    this.element.addClass("pending")
    this.element.removeClass("success")
    this.element.removeClass("failure")
    let persisting = $.post(
      `/concern/${this.class_name}/${this.id}.json`,
      this.params()
    ).done((response) => {
      this.element.data('version', response.version)
      this.element.data("current-order", this.order)
      this.element.addClass("success")
      this.element.removeClass("failure")
    }).fail(() => {
      this.element.addClass("failure")
      this.element.removeClass("success")
    }).always(() => {
      this.element.removeClass("pending")
    })
    return persisting
  }

  params() {
    let params = {}
    params[this.singular_class_name] = {
      "version": this.version,
      "ordered_member_ids": this.order
    }
    params["_method"] = "PATCH"
    return params
  }

  get_sort_position(item) {
    return this.element.children().index(item)
  }

  register_order_change() {
    if(this.order.toString() != this.element.data("current-order").toString()) {
      this.save_manager.push_changed(this)
    } else {
      this.save_manager.mark_unchanged(this)
    }
  }

  get stopped_sorting() {
    return (event, ui) => {
      this.sorting_info.end = this.get_sort_position($(ui.item))
      if(this.sorting_info.end == this.sorting_info.start) {
        return
      }
      this.register_order_change()
    }
  }

  get started_sorting() {
    return (event, ui) => {
      this.sorting_element = $(ui.item)
      this.sorting_info.start = this.get_sort_position(ui.item)
    }
  }

  get id() {
    return this.element.data("id")
  }

  get class_name() {
    return this.element.data("class-name")
  }

  get singular_class_name() {
    return this.element.data("singular-class-name")
  }

  get order() {
    return $("*[data-reorder-id]").map(
      function() {
        return $(this).data("reorder-id")
      }
    ).toArray()
  }

  get version() {
    return this.element.data('version')
  }

  get alpha_sort_button() {
    return $("*[data-action='alpha-sort-action']")
  }

  initialize_alpha_sort_button() {
    let that = this
    this.alpha_sort_button.click(function() { that.sort_alpha() } )
  }

  sort_alpha() {
    // create array of { title, element } objects
    let array = []
    let children = this.element.children().get()
    children.forEach(function(child) {
      let title = $(child).find("input.title").val()
      array.push(
        { title: title,
          element: child }
      )
    })
    // sort array by title of each object
    array.sort(function(o1, o2) {
      let a = o1.title.toLowerCase()
      let b = o2.title.toLowerCase()
      return a < b ? -1 : (a > b ? 1 : 0);
    });
    // replace contents of #sortable with elements from the array
    this.element.empty()
    for (let child of array) {
      this.element.append(child.element)
    }
    this.register_order_change()
  }
}
