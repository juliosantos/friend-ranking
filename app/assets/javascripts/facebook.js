var Facebook = (function () {

  var user = {};

  var authenticate = function( permissions, sharedobject_id ) {
    var d = $.Deferred();

    permissions = permissions || "user_likes,friends_likes";

    FB.login( function( response ) {
      if ( response.authResponse && response.authResponse.accessToken ) {
        user.access_token = response.authResponse.accessToken;
        $.post( "/users/create_and_or_sign_in", {
          access_token : user["access_token"]
        }, function () {
          d.resolve();
        } );
      } else {
        // 'User cancelled login or did not fully authorize.'
        d.reject();
      }
    }, { scope: permissions } );    

    return d;
  };

  var isUserAuthenticated = function () {
    var d = $.Deferred();

    FB.getLoginStatus( function (response) {
      if (response.status === "connected") {
        user.access_token = response.authResponse.accessToken;
        d.resolve();
      } else {
        d.reject();
      }
    });

    return d;
  };

  var getUser = function () {
    return user;
  }

  return {
    authenticate : authenticate,
    getUser : getUser,
    isUserAuthenticated : isUserAuthenticated
  }
}());
