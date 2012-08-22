FriendRank = (function () {
  var config = {};
  var splinesInterval;
  var friendsLikesInterval;
  var friendsNames = [];

  var facebookReady = function () {
    FB.init({
        appId      : window.AppConfig.FB_APP_ID, // App ID
        channelURL : window.APP_URL + '/channel.html', // Channel File
        status     : true, // check login status
        cookie     : true, // enable cookies to allow the server to access the session
        oauth      : true, // enable OAuth 2.0
        xfbml      : true  // parse XFBML
      });
      $( document ).trigger( "facebook:ready" );
  };

  var init = function (c) {
    config = c;
    $( document ).ready( function () {
      $( document ).on( "facebook:ready", function () {
        reticulateSplines();
        attachClickHandlers();
        handleLogin();
      });
    });
  };

  var reticulateSplines = function () {
    $p = $( "#splines p" );
    $p.text( "Reticulating splines" );
    splinesInterval = setInterval( function () {
      $p.append( "." );
    }, 200 );
  };

  var attachClickHandlers = function () {
    $( "a#login" ).click( function (e) {
      var deferred = Facebook.authenticate();
      var button = $( this );

      button.button( "loading" );

      deferred.done( function () {
        $( "#login-modal" ).modal( "hide" );
        showControls();
      });

      deferred.fail( function () {
        button.button( "repeat" );
      });

      e.preventDefault();
    });

    $( "a#get-friends" ).click( function (e) {
      $( "a#get-friends" ).button( "loading" );
      getFriends();
      e.preventDefault();
    });

    $( "button#get-friends-likes" ).parents( "form" ).submit( function (e) {
      $( this ).find( "button" ).button( "loading" );
      getFriendsLikes();
      e.preventDefault();
    });

    $( "button#get-top-friends" ).parents( "form" ).submit( function (e) {
      $( this ).find( "button" ).button( "loading" );
      getTopFriends();
      e.preventDefault();
    });
  };

  var handleLogin = function () {
    var deferred = Facebook.isUserAuthenticated();

    // returning user
    deferred.done( function () {
      $.post( "/users/create_and_or_sign_in", { access_token : Facebook.getUser().access_token }, function () {
        showControls();
      });
    });

    // first time user
    deferred.fail( function () {
      $( "#splines" ).slideUp();
      $( "#login-modal" ).modal();
    });
  };

  var showControls = function () {
    var deferred = $.Deferred();

    if (window.location.hash === "#step3") {
      $( "a[href=#step3]" ).tab( "show" );
      getFriends().pipe( getFriendsLikes ).pipe( deferred.resolve );
    } else {
      deferred.resolve();
    }

    deferred.done( function () {
      $( "#splines" ).slideUp();
      clearInterval( splinesInterval );
      $( "#controls" ).slideDown();
    });
  };

  var getFriends = function () {
    var deferred = $.Deferred();

    $.get( "/users/friends", { access_token : Facebook.getUser().access_token }, function (friends) {
      $( "a#get-friends" ).button( "reset" );

      var friendRowTemplate = $( "#friend-row" ).html();
      var $table = $( "table#friends-table" );
      var $tbody = $table.children( "tbody" );
      $tbody.empty();

      _.each( friends, function (friend) {
        friendsNames.push( friend.name );
        var tr = _.template( friendRowTemplate, {
          friendID : friend.facebook_uid,
          picture : "https://graph.facebook.com/" + friend.facebook_uid + "/picture?type=square",
          debug : "http://developers.facebook.com/tools/explorer/356563911085350/?method=GET&path=" + friend.facebook_uid,
          name : friend.name,
          likes_count : "<a href='javascript:void(0)' rel='popover'><i class='icon-question-sign'></i></a>"
        });
        $tbody.append( tr );
      });

      $( "a[rel=popover]" ).popover({
        title : "Chill!",
        trigger : "hover",
        content : "<p>We'll fill out these missing numbers on the next step.</p>"
      });

      $( "#friends" ).show();

      $( "#step3" ).find( "input[type=text]" ).typeahead( {source : friendsNames} );

      deferred.resolve();
    }).error( function (e) {
      $( "a#get-friends" ).button( "repeat" );
    });

    return deferred;
  };

  
  var getFriendsLikes = function () {
    var deferred = $.Deferred();

    var email = $( "#step2" ).find( "input[type=text]" ).val();
    var unicorns = $( "#step2" ).find( "input[type=checkbox]" ).attr( "checked" ) === "checked"
    $.get( "/users/friends_likes", { access_token : Facebook.getUser().access_token, email : email, unicorns : unicorns }, function (friendsLikesCount) {
      if (friendsLikesCount === "pending") {
        friendsLikesInterval = setInterval( checkForFriendsLikes, 5000 );
      } else {
        $( "button#get-friends-likes" ).button( "reset" );

        var $tbody = $( "table#friends-table tbody" );

        _.each( friendsLikesCount, function (friendLikesCount) {
          $tbody.children( "#" + friendLikesCount.facebook_uid ).children( "td.likes-count" ).text( friendLikesCount.likes_count );
        });

        $( "a[rel=popover]" ).popover( "destroy" );
        $( "i.icon-question-sign" ).removeClass( "icon-question-sign" ).addClass( "icon-warning-sign" );
        $( "a[rel=popover]" ).popover({
          title : "Privacy freak alert!",
          trigger : "hover",
          content : "<p>Facebook allows users to prevent their friends from taking their data with them when they use apps. In these cases, the <strong>friends_likes</strong> permission doesn't help.</p>"
        });
      }

      deferred.resolve();
    }).error( function (e) {
      $( "button#get-friends-likes" ).button( "repeat" );
    });
    
    return deferred;
  };

  var checkForFriendsLikes = function () {
    $.get( "/users/friends_likes_status", { access_token : Facebook.getUser().access_token }, function (status) {
      if (status === "complete") {
        clearInterval( friendsLikesInterval );
        getFriendsLikes();
      }
    });
  };

  var getTopFriends = function () {
    $.get( "/users/top_friends", { access_token : Facebook.getUser().access_token }, function (friends) {
      $( "button#get-top-friends" ).button( "reset" );

      var friendRankedRowTemplate = $( "#friend-ranked-row" ).html();
      var $table = $( "table#friends-ranked-table" );
      var $tbody = $table.children( "tbody" );
      $tbody.empty();

      _.each( friends, function (friend, index) {
        var tr = _.template( friendRankedRowTemplate, {
          friendID : friend.facebook_uid,
          picture : "https://graph.facebook.com/" + friend.facebook_uid + "/picture?type=square",
          debug : "http://developers.facebook.com/tools/explorer/356563911085350/?method=GET&path=" + friend.facebook_uid,
          name : friend.name,
          likes_count : friend.n_common_likes
        });
        $tbody.append( tr );
      });

      _.each( $tbody.find( "a" ), function (anchor) {
        var $anchor = $( anchor );
        $anchor.click( function (e) {
          $anchor.button( "loading" );
          getCommonLikes( $anchor.parents( "tr" ).attr( "id" ) );
          e.preventDefault();
        });
      });

      $( "#friends" ).hide();
      $( "#friends-ranked" ).show();

      $( ".alert" ).hide();
      var guess = $( "#step3" ).find( "input[type=text]" ).val();

      var top_friends = _.pluck( _.select( friends, function (f) { return f.n_common_likes === friends[0].n_common_likes; } ), "name" )
      
      if (_.include( top_friends, guess )) {
        var $alert_success = $( ".alert-success" );
        $alert_success.text( $alert_success.text().replace( /FRIEND_NAME/, guess ) );
        $alert_success.slideDown();
      } else {
        var $alert_error = $( ".alert-error" );
        $alert_error.text( $alert_error.text().replace( /FRIEND_NAME/, top_friends[0] ) );
        $alert_error.slideDown();
      }

    }).error( function (e) {
      $( "button#get-friends" ).button( "repeat" );
    });
  };
  
  var getCommonLikes = function (friend_id) {
    var $tr = $( "table#friends-ranked-table" ).find( "tr#" + friend_id );

    $.get( "/users/common_likes", { access_token : Facebook.getUser().access_token, friend_facebook_uid : friend_id }, function (common_likes) {
      $tr.find( "a" ).button( "reset" );

      var $modal = $( "#likes-modal" );
      var likeTemplate = $( "#like" ).html();
      var $ul = $modal.find( "ul" );
      $ul.empty();

      _.each( common_likes, function (like) {
        var li = _.template( likeTemplate, {
          name : like["name"],
          url : "http://facebook.com/" + like["fb_id"],
          picture : "https://graph.facebook.com/" + like["fb_id"] + "/picture?type=square"
        });
        $ul.append( li );
      });

      $ul.find( "a" ).tooltip( {animation : false} );

      var friend_name = $( $tr.children( "td" )[1] ).text().trim();
      $modal.find( "h3" ).text( "Common likes with " + friend_name );
      $modal.modal();
    }).error( function (e) {
      $tr.find( "a" ).button( "repeat" );
    });
  };

  return {
    init : init,
    facebookReady : facebookReady
  }
}());
