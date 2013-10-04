var AWS = require('aws-sdk');
AWS.config.loadFromPath('./creds/amazon-credentials.json');
var dynamodb = new AWS.DynamoDB();

dynamodb.describeTable({ TableName: "vf-users" }, function (err, data) {
  if (err) {
    console.log(err);
    if (err.code == "ResourceNotFoundException") {
    	dynamodb.createTable({
			TableName: "vf-users",
			AttributeDefinitions: [
				{ AttributeName: 'email', AttributeType: 'S' }
			],
			KeySchema: [
				{ AttributeName: 'email', KeyType: 'HASH' }
			],
			ProvisionedThroughput: {
				ReadCapacityUnits: 5,
				WriteCapacityUnits: 3
			}
		}, console.log);
    } 
  } else {
    console.log(data); // successful response
  }
});

// create user account 
exports.create = function (user) {
	// body...
};

// add 3rd party integration to user account
exports.addIntegration = function (user, integration) {

};