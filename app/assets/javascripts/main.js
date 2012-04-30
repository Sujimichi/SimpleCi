//AJAX methods GET, POST and DELETE - Generalised methods for making ajax requests
function ajax_get(url, data, callback){
  ajax_send(url, data, update_callback(callback), "GET")
};
function ajax_post(url, data, callback){
  ajax_send(url, data, update_callback(callback), "POST")
};
function ajax_put(url, data, callback){
  ajax_send(url, data, update_callback(callback), "PUT")
};
function ajax_delete(url, data, callback){
  ajax_send(url, data, update_callback(callback), "DELETE")
};

function ajax_send(url, data, callback, type){
  //wrapped_callback and wapped_error simply takes the actions defined as success: and error: in the callback
  //and wraps then in another function which a) calls the original success: or error: function and b) makes a call to reset_loader_links
  $.ajax({ url: url, data: data, type: type, success: callback['success'], error: callback['error'], dataType: 'script' });
};


function update_callback(cb){


  return cb;
};

//Main Popup Method Called by Everything which requires a popup
function popup(div_name, data, args, title, css_class){
  args['id'] = div_name; args['css'] = css_class; args['title'] = title;
  alert("error")
  //new Dialog(data, args);
};

function reset_loader_links(){};
