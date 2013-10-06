var http = require('http');
var express = require('express');
var passport = require('passport');
var OAuth2Strategy = require('passport-oauth').OAuth2Strategy;
var path = require('path');
var routes = require('./routes');
var utils = require('./utils/utils');

var app = express();

passport.serializeUser(function(user, done) {
  done(null, user);
});

passport.deserializeUser(function(obj, done) {
  done(null, obj);
});

// all environments
app.set('host', process.env.IP || "127.0.0.1");
app.set('port', process.env.PORT || 59721);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(express.cookieParser());
app.use(express.session({ secret: 'oauth2-sc' }));
app.use(passport.initialize());
app.use(passport.session());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'client')));

passport.use('provider', new OAuth2Strategy(
  {
    authorizationURL: 'http://dev1login.servicechannel.com/oauth/authorize',
    tokenURL: 'http://dev1login.servicechannel.com/oauth/token',
    clientID: 'SB.2000001305.88ECE264-2287-4166-9E31-21BBB39E575D',
    clientSecret: '52E13150-A280-4069-9411-D5B5B82C3D3E',
    callbackURL: 'http://localhost:59721/auth/provider/callback'
  },
  function(accessToken, refreshToken, profile, done) {
    console.log('accessToken: ' + accessToken);
    console.log('refreshToken: ' + refreshToken);
    console.log('profile: ' + utils.toString(profile));
    console.log('done: ' + done);
    process.nextTick(function () {
      return done(null, profile);
    });
  }
));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

// Redirect the user to the OAuth 2.0 provider for authentication.  When
// complete, the provider will redirect the user back to the application at
//     /auth/provider/callback
app.get('/auth/provider', passport.authenticate('provider', { scope: ['email', 'SubscriberUserDelete', 'SubscriberUsersGet'] }));

// The OAuth 2.0 provider has redirected the user back to the application.
// Finish the authentication process by attempting to obtain an access
// token.  If authorization was granted, the user will be logged in.
// Otherwise, authentication has failed.
app.get('/auth/provider/callback', 
  passport.authenticate('provider', { successRedirect: '/',
                                      failureRedirect: '/login' }));
app.get('/', routes.index);

http.createServer(app).listen(app.get('port'), app.get('host'), function() {
  console.log('Express server listening on port ' + app.get('port'));
});