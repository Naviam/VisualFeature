var http = require('http');
var express = require('express');
var socket = require('socket.io');

var routes = require('./routes');
var sns = require('./routes/sns');
// var user = require('./routes/user');
// var environments = require('./routes/environments');
var path = require('path');

var app = express();
//var io = socket.listen(app);

// all environments
app.set('port', process.env.PORT || 3000);
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'client')));

// development only
if ('development' == app.get('env')) {
  app.use(express.errorHandler());
}

app.get('/', routes.index);
app.get('/dashboard', routes.dashboard);
app.post('/sns', sns.sns);

http.createServer(app).listen(process.env.PORT, process.env.IP, function(){
  console.log('Express server listening on port ' + app.get('port'));
});