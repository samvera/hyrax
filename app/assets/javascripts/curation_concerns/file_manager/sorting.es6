{
  Blacklight.onLoad(function() {
    window.new_sort_manager = new SortManager
  })

  class SortManager {
    constructor() {
      this.element = $("#sortable")
      this.sorting_info = {}
      this.initialize_sort()
      this.element.data("current-order", this.order)
      this.save_manager = window.save_manager
    }

    initialize_sort() {
      this.element.sortable({handle: ".panel-heading"})
      this.element.on("sortstop", this.stopped_sorting)
      this.element.on("sortstart", this.started_sorting)
    }

    persist() {
      let params = {}
      params[this.singular_class_name] = {
        "ordered_member_ids": this.order
      }
      params["_method"] = "PATCH"
      this.element.addClass("pending")
      this.element.removeClass("success")
      this.element.removeClass("failure")
      let persisting = $.post(
        `/concern/${this.class_name}/${this.id}`,
        params
      ).done(() => {
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

    get_sort_position(item) {
      return this.element.children().index(item)
    }

    get stopped_sorting() {
      return (event, ui) => {
        this.sorting_info.end = this.get_sort_position($(ui.item))
        if(this.sorting_info.end == this.sorting_info.start) {
          return
        }
        if(this.order.toString() != this.element.data("current-order").toString()) {
          this.save_manager.push_changed(this)
        } else {
          this.save_manager.mark_unchanged(this)
        }
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
  }
}
