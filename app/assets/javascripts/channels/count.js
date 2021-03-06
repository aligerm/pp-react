jQuery(document).ready(function() {
	var count;
	count = $('#count_channel');
	if ($('#count_channel').length > 0) {
		App.count = App.cable.subscriptions.create({
		   channel: "CountChannel",
      	   game_id: count.data('game-id')
    	}, {
          connected: function() {
			  return console.log('connected');
		  },
          disconnected: function() {
			  return console.log('disconnected');
		  },
          received: function(data) {
			  if (data['state'] == 'wait') {
				  if( $('#count-reload').length > 0 ) {
				  	window.location.reload();
			  	  } else {
					  $('#count').text(data['count']);
					  document.getElementById('ping').play();
					  var left1 = Math.random() * 80;
					  var userDIV = '<img src="'+data['avatar']+'" style="left:' + left1 +'%;">';
					  $('#user-rain').append(userDIV);
				  }
			  }
			  if (data['choose'] == true) {
				  if(data['site'] == 'left') {
				  	var userDIV = '<div class="rain"><img src="'+data['avatar']+'"></div>';
					$('#left-img').addClass('pulse-single');
				  	$('.circle-left').append(userDIV);
					document.getElementById('ping').play();
				  } else {
					var userDIV = '<div class="rain"><img src="'+data['avatar']+'"></div>';
					$('#right-img').addClass('pulse-single');
				  	$('.circle-right').append(userDIV);
					document.getElementById('ping').play();
				  }
			  }
			  if (data['objection'] == true) {
				  var userDiv = '<div class="objection"><div class="text" >'+data['objection_text']+'</div><div class="otimer">00:15</div></div>';
				  if(data['objection_sound'] != "") {
					  userDiv += '<audio src="'+data['objection_sound']+'" id="objection_sound" />'
				  }
				  $('#content').prepend(userDiv);
				  startObjectionTimer();
			  }
			  if (data['comment'] == true) {
				  var userDiv = '<div class="comment"><img src="'+data['comment_user_avatar']+'"><div class="text-bg">'+data['comment_text']+'</div><div class="text">'+data['comment_text']+'</div></div>';
				  $('#game_comments').append(userDiv);
			  }
			  if (data["emoji"] == true) {
				  var userDiv = '<div class="comment"><img src="'+data['user_avatar']+'"><div class="emoji">'+data["emoji_icon"]+'</div>'
				  $('#game_comments').append(userDiv);
			  }
		  }
		});
		$(window).bind('beforeunload', function(){
      		App.count.unsubscribe()
    	});
	}
});
