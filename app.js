var http = require('http');
var express = require('express');
var passport = require('passport');
var util = require ('util');
var GitHubStrategy = require('passport-github').Strategy;
var socket = require('socket.io');
var path = require('path');
var routes = require('./routes');
var sns = require('./routes/sns');

var app = express();
//var io = socket.listen(app);

// https://github.com/organizations/Naviam/settings/applications/60403
var GITHUB_CLIENT_ID = "688b3527f940fb337d1f";
var GITHUB_CLIENT_SECRET = "7411bdd4c7347721c414b2b260d6a8461f605d9b";
var GITHUB_CALLBACK_URL = "http://visual-feature-c9-hatalski.c9.io/auth/github/callback";

GLOBAL.GITHUB_ACCESS_TOKEN = null;

// Passport session setup.
//   To support persistent login sessions, Passport needs to be able to
//   serialize users into and deserialize users out of the session.  Typically,
//   this will be as simple as storing the user ID when serializing, and finding
//   the user by ID when deserializing.  However, since this example does not
//   have a database of user records, the complete GitHub profile is serialized
//   and deserialized.
passport.serializeUser(function(user, done) {
  done(null, user);
});

passport.deserializeUser(function(obj, done) {
  done(null, obj);
});

// all environments
app.set('host', process.env.IP || "127.0.0.1");
app.set('port', process.env.PORT || 3000);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(express.cookieParser());
app.use(express.session({ secret: 'SECRET' }));
app.use(passport.initialize());
app.use(passport.session());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'client')));

passport.use(new GitHubStrategy({
    clientID: GITHUB_CLIENT_ID,
    clientSecret: GITHUB_CLIENT_SECRET,
    scope: "user,repo",
    callbackURL: GITHUB_CALLBACK_URL
  },
  function(accessToken, refreshToken, profile, done) {
    console.log('accessToken: ' + accessToken);
    console.log('refreshToken: ' + refreshToken);
    console.log('profile: ' + profile);
    console.log('done: ' + done);
    // asynchronous verification, for effect...
    process.nextTick(function () {
      
      // To keep the example simple, the user's GitHub profile is returned to
      // represent the logged-in user.  In a typical application, you would want
      // to associate the GitHub account with a user record in your database,
      // and return that user instead.
      GLOBAL.GITHUB_ACCESS_TOKEN = accessToken;
      return done(null, profile);
    });
    // User.findOrCreate({ githubId: profile.id }, function (err, user) {
    //   return done(err, user);
    // });
  }
));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

app.get('/auth/github', passport.authenticate('github'));
app.get('/auth/github/callback', 
  passport.authenticate('github', { failureRedirect: '/' }),
  function(req, res) {
    // Successful authentication, redirect home.
    res.redirect('/dashboard');
  });
app.get('/logout', function(req, res){
  req.logout();
  GLOBAL.GITHUB_ACCESS_TOKEN = null;
  res.redirect('/');
});
app.get('/', routes.index);
app.get('/dashboard', ensureAuthenticated, routes.dashboard);
app.get('/repositories/:org', routes.repositories);
app.get('/stories/:owner/:repo', routes.stories);
app.post('/sns', sns.sns);

http.createServer(app).listen(app.get('port'), app.get('host'), function(){
  console.log('Express server listening on port ' + app.get('port'));
});

// Simple route middleware to ensure user is authenticated.
//   Use this route middleware on any resource that needs to be protected.  If
//   the request is authenticated (typically via a persistent login session),
//   the request will proceed.  Otherwise, the user will be redirected to the
//   login page.
function ensureAuthenticated(req, res, next) {
    console.log("is authenticated: " + req.isAuthenticated());
    if (req.isAuthenticated()) { return next(); }
    res.redirect('/')
}