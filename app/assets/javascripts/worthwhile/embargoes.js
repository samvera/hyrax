Blacklight.onLoad(function () {
  $("[data-behavior=\"extra\"]").hide()
  function reveal(id) {
    $("[data-behavior=\"extra\"][data-id=\"" + id + "\"]").show();
  }

  function hide(id) {
    $("[data-behavior=\"extra\"][data-id=\"" + id + "\"]").hide();
  }
  $(".batch_document_selector").click(function() {
    if (this.checked) {
      reveal($(this).attr('value'));
    } else {
      hide($(this).attr('value'));
    }
  })
});
