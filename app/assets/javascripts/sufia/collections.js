function modal_collection_list(action, event){
  if(action == 'open'){
    $(".collection-list-container").css("visibility", "visible");
  }
  else if(action == 'close'){
    $(".collection-list-container").css("visibility", "hidden");
  }

  event.preventDefault();
}
