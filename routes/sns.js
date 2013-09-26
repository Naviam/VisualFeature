/*
 * POST SNS notification.
 */

var AWS = require('aws-sdk');
AWS.config.update({accessKeyId: 'akid', secretAccessKey: 'secret'});

exports.sns = function(req, res){
  var client = new AWS.SNS();
  client.listTopics({}, function(err, data) {
      res.write(JSON.stringify(data.Topics));
  });
  res.end();
};