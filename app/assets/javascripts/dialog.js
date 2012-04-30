var dialog_container = '#popup_holder';


function this_dialog(e){

  target = e;
  container = undefined;

  for(i in active_dialogs){
    $('#' + active_dialogs[i].dialog_id).map(function(){
      if( this == target ) {
        container_id = active_dialogs[i].dialog_id;
      };

    });
  };

  alert(container_id);
};


//Idea for replacement for confirm()
//new DialogConfirm("do you stink?", [
//    {text: "Cancel",  click: function(){ close_popup('edit_entity') } },
//    {text: "OK",      click: function(){ close_popup('edit_entity') } }
//  ]
//
//])


function Dialog(html, args){

  this.settings = {
    bgiframe: true,
    modal: false,
    width: 700,
    height: 300,
    closeOnEscape: true,
    zIndex: 3000,
    show: "fade",
    hide: "fade",
    position: ["center", 100],
    id: "annonymouse_dialog",  //yes, I know, dyslexic. GIVE YOUR PANELS IDS or the mouse gets it!!
    title: "no title",
    css: "",
    auto_height: true,
    auto_width:  false,
    min_width: 580,
    load_resize_delay: 0

  };

  this.initialize = function(html, args){ //Yeah its Ruby-like-syntax, deal
    if(html == undefined){var html = "<div>NO CONTENT</div>"};
    this.html = "<div class='dialog_content'>" + html + "</div>";

    $.extend(this.settings, args)  //merge the given args with (overwriting) default settings
    this.dialog_id = this.settings.id;
    this.wrap_functions();

    //create the html for the dialog and insert into the dialog_container element - this.make_div()
    //then call jQuery's dialog method on that div passing in the args this.settings
    $(this.make_div()).dialog(this.settings);
    $('#' + this.dialog_id).find(".dialog_content").animate({opacity: 0},0)
    this.autosize(this.settings.load_resize_delay)

    var self = this;
    var fade_in_time = (rails_env == "test") ? 100 : 800
    setTimeout(function(){
      $('#' + self.dialog_id).find(".dialog_content").animate({opacity: 1}, fade_in_time)
    },100)


    if(this.settings.close_protection == true){
      this.close_protection('on')
    };

    active_dialogs[this.dialog_id] = this;  //register the dialog in the active_dialogs hash
  };


  this.make_div = function(){
    var div = '#' + this.dialog_id;
    $(div).remove();
    $(dialog_container).html("<div id='" + this.dialog_id + "' class='"+ this.settings.css +"' title='" + this.settings.title + "'>"+ this.html + "</div>");
    //set the id in the div's data so it can be used to return to this instance
    $(div).find(".ui-dialog-content").data("dialog_id", this.dialog_id);
    $(div).find(".dialog_content").data("dialog_id", this.dialog_id);

    this.div = div;
    return div;
  };

  this.set_html = function(data){
    div = "#" + this.dialog_id;
    if(data == undefined){
      return $(div).html();
    }else{
      this.html = "<div class='dialog_content'>" + data + "</div>";
      $(div).html(this.html);
    };
  };

  //passthrough to the jquery dialog method
  //a bit experimental, not really working. just use $('#' + this.dialog_id).dialog();
  this.dialog = function(){ return $('#' + this.dialog_id).dialog(arguments) };

  //Close the dialog and remove it from the page.  Currently there is no use case for closing a dialog but keeping it alive
  this.close = function(){
    $('#' + this.dialog_id).dialog("close");
  };

  //destroy and remove the dialog from the page
  this.remove = function(){
    this.dialog("destroy");
    $('#' + this.dialog_id).remove();
    delete active_dialogs[this.dialog_id];
  };


  //enable or disable close_protection by passing args "on" or "off".  No args returns current state.
  //close protection simply monitors a set of elements by binding an onchange event to them.  If an
  //element is changed it will set the dialog.has_changed to true.  This is then checked in ok_to_close
  //ok_to_close is called on beforeClose - see wrap_function at bottom.
  this.close_protection = function(args){
    var onchange_types = ['input', 'textarea'];
    var ignore_elements= ['visible_states']
    if(args == "on"){
      this.has_changed = false;
      this.close_protection_active = true;
      for(i in onchange_types){
        $('#' + this.dialog_id).find(onchange_types[i]).each(function(){
          $(this).data("value_before_change", $(this).val());
        });
      };
    }else if(args=="off"){
      this.close_protection_active = false;
    }else{
      return this.close_protection_active;
    };
  };

  //If close protection is active and any of the watched elements have had a 'changed' event
  //then this will prompt the user that they will loose changes.  close_protection needs to be disbaled before save is called.
  this.ok_to_close = function(){
    if(this.close_protection_active){
      var onchange_types = ['input', 'textarea'];
      var self = this;
      for(i in onchange_types){
        $('#' + this.dialog_id).find(onchange_types[i]).each(function(){
          var prev = $(this).data("value_before_change");
          var val = $(this).val();
          if(prev != val){
            self.has_changed = true
          };
        });
      };

      if(this.has_changed == true){
        if(confirm("You have unsaved changes\n Press OK to Discard your changes or Cancel to Keep them") == true){
        //if(confirm("You have not saved your changes you moron\nI mean really? Good thing I'm here\nNow what do you want to do; \n\nOK to close, Cancel to keep dialog open;") == true){
          return true }else{ return false
        };
      };
    }else{ return true };
  };


  this.set_button_loaders = function(){
    $('.ui-dialog-buttonpane').find('.ui-button').each(function(){ set_remote_button(this) });
  };


  //resize the dialog to fit its contents - height and width handeled separatly
  this.autosize = function(delay){

    if(delay == undefined){var delay = 200};
    var self = this;
    setTimeout(function(){
      //alert("called " + self.dialog_id)
      height_args = self.resize_height();
      width_args = self.resize_width();
    }, delay)
  };

  this.resize_height = function(new_height){
    //var method = function(){return false};
    var div = $('#' + this.dialog_id)
    var content_class = $(div).find('.dialog_content');
    var dialog_class  = $(div).find('.dialog_content').parents('.ui-dialog-content');



    var height = this.settings.height;  //set the height according to settings
    if(this.settings.auto_height){ var height = $(content_class).height() + 15 }; //override with content height if auto_height

    if(this.settings.auto_height || new_height){

      if(new_height){var height = new_height};

      //prevent overlap of the bottom of the page
      if($(content_class).offset() != null){
        //var f = $('#footer').offset().top - 50  //TODO this needs fixing for when the footer is big
        footer_bottom = $('#footer').offset().top + $('#footer').height();
        var f = footer_bottom - 100;
        if(height + $(dialog_class).offset().top >= f){
          height = f - $(dialog_class).offset().top;
        };
      };

      var n_buttons = $('#' + this.dialog_id).dialog( "option", "buttons").length;
      if( n_buttons == undefined || n_buttons == 0){ var button_padding = 50 }else{ var button_padding = 110}; //115 padding needed for those dialogs with buttons

      //resize ui-dialog-content to fit the main content.
      $(dialog_class).animate({height: height}, 200)
      //while this 2nd animation is not actually needed to get the dialog to resize correctly it greatly smoothes the animation
      //without this I think ui-dialog is resized automattically but results in more scroll bar being drawn than if it is anumated at the same time.
      var self = this;
      $(dialog_class).parents('.ui-dialog').animate({height: height + button_padding }, 200, function(){
        if(!self.settings.auto_width){ self.set_scroll_visibility() }; //dont call set_scoll_vis here as it is also called in resize_width if auto_width is true.
      })
    };
  };

  //dialogs have overflow hidden by default so no scroll is shown.  If the content of the dialog is longer than the dialog itself then this applies or removes vertial scroll
  this.set_scroll_visibility = function(){
    var div = $('#' + this.dialog_id)
    var content_class = $(div).find('.dialog_content');
    var dialog_class  = $(div).find('.dialog_content').parents('.ui-dialog-content');

    if($(content_class).height() > $(dialog_class).height()){
      $(dialog_class).css('overflow-y', "scroll")
      //In the case of the entity edit dialog (which is a bit non-standard) the padding needs to be compensated when a scroll bar is present.
      if( $(div).hasClass("edit_entity_dialog")){ $(content_class).addClass('vert_scroll_compensate') };
    }else{
      $(dialog_class).css('overflow-y', "hidden")
      $(content_class).removeClass('vert_scroll_compensate');
    };
  };


  this.resize_width = function(new_width){
    var div = $('#' + this.dialog_id)
    var content_class = $(div).find('.dialog_content');
    var dialog_class  = $(div).find('.dialog_content').parents('.ui-dialog-content');

    var width = this.settings.width;
    var min_width = this.settings.min_width;

    if(this.settings.auto_width){
      if(this.settings.auto_width != true && this.settings.auto_width != false){  //might be better reg_exp for line starting '.' or '#'
        var width = $(this.settings.auto_width).width() + 40;
      }else{
        var cap = 9000; //should probably be set to screen width
        widths = $('#' + this.dialog_id).map(function(){
          var w = $(this).width();
          return (w >= cap) ? 0 : w
        }).get();
        var width = Math.max.apply(Math, widths);
      };
    };

    if(this.settings.auto_width || new_width){
      if(new_width){var width = new_width};
      if(width <= min_width){width = min_width}

      //prevent dialog from overlapping right edge
      var left_edge = $("#" + this.dialog_id).offset().left
      var right_edge_clipped = left_edge + width > $('#body').width(); //is the right edge of the edge of page?
      if(right_edge_clipped  || this.settings.auto_center){         //if right edge is over, or settings.auto_center is true then re_center the
        var left = $('#body').width() / 2 - (width / 2)
        $("#" + this.dialog_id).parents('.ui-dialog').animate({left: left}, 300)
      };

      //resize ui-dialog-content to fit the main content.
      $(dialog_class).animate({width: width}, 100)
      //while this 2nd animation is not actually needed to get the dialog to resize correctly it greatly smoothes the animation
      //without this I think ui-dialog is resized automattically but results in more scroll bar being drawn than if it is anumated at the same time.
      var self = this;
      $(dialog_class).parents('.ui-dialog').animate({width: width + 18 }, 100, function(){
        self.set_scroll_visibility()
      })
    };
  };


  //wrap_functions looks for certain functions being passed to the jQuery dialog hook ie "open", "close"
  //These functions are wrapped in an outer function which calls them and also performs actions which
  //are applicalble to all dialogs.
  this.wrap_functions = function(){
    var self = this;

    var close_method = this.settings["close"]
    this.settings["close"] = function(event, ui){             //replace function on the close hook.
      if(close_method != undefined){close_method(event, ui)}; //call any existing close method
      //self.remove(); //destroy and remove dialog
      setTimeout(function(){ self.remove() }, 300);

    };

    var skip_before_close = false;  //Skip before close is used as a nasty workaround for a problem with jQuery
    //The problem is that the beforeClose event is called twice when esc is pressed as apposed to once (like it should) when a close botton is clicked.
    //The results in the user getting the "do you want to save changes" message twice.
    //To get arround this skip_before_close is set to true when the beforeClose method return false.  A timer will set it back to true in 10ms.
    //If in that 10ms another call to beforeClose is made then the method simply returns false and skips the rest of its execution.
    var before_close_method = this.settings["beforeClose"]
    this.settings["beforeClose"] = function(event, ui){             //replace function on the hook.
      if(skip_before_close == true){return false};        //SKIP BEFORE CLOSE if skip_before_close is true - see above comment.
      if(before_close_method != undefined){before_close_method(event, ui)}; //call any existing beforeClose method
      var r = self.ok_to_close();  //Check if user data has changed and prompt user, returns true or false.
      if(r == false){
        skip_before_close = true; //being set to true will force beforeClose to return false - effectivly skipping the method.
        setTimeout(function(){skip_before_close = false},10);   //revert back to true in 10ms.  second call to beforeClose comes almost instantly so only small window needed.
        setTimeout(function(){reset_loader_links() },10);

      };
      return r;
    };

    var open_method = this.settings["open"]
    this.settings["open"] = function(event, ui){
      if(open_method != undefined){open_method(event, ui)}; //call any existing open method
      enable_ajax_loader_links();  //also calls enable_twostep_links();
      set_help_links();
      self.set_button_loaders();
    };

  };

  //Initialize the dialog!!
  //call the initialize method to open the dialog
  this.initialize(html, args);


  /*
  //Experimental Stuff!!

  //Automatic Automatic resize - Basic idea: set up a poller to watch the height or width of the dialogs content.
  //If on a poll the size has changed then it should call the autosize method.
  //Simple right, hmmmm.
  this.automatic_autosize = function(){  //yes I know, the name sucks, but it automatically sets the size automatically.

    if(this.current_size == undefined){
      this.current_size = {width: $('#' + this.dialog_id).find('.dialog_content').width(), height: $('#' + this.dialog_id).find('.dialog_content').height() };
    };

    this.observe_size = true
    this.poll_size();


  };
  this.poll_size = function(){
    if(this.observe_size != true){return false };

    var changed = false;
    var div = '#' + this.dialog_id;
    w = $(div).find('.dialog_content').width();
    h = $(div).find('.dialog_content').height();
    if(this.current_size.width != w ){ changed = true};
    if(this.current_size.height != h){ changed = true};

    var self = this;
    if(changed){
      //alert("changed size: was'" + this.current_size.height + "' is now'"+ h +"'");
      this.current_size = {width: $('#' + this.dialog_id).find('.dialog_content').width(), height: $('#' + this.dialog_id).find('.dialog_content').height() };
      self.resize_height();
      self.resize_width();

      setTimeout(function(){self.poll_size() }, 500);
    }else{
      setTimeout(function(){self.poll_size() }, 500);
    };
  };

  */



};
