var GitHubApi = require("github");

var token = "34387f02666e40c9a6b9409ba15a45ba7beaa7ac";
var github = new GitHubApi({
    // required
    version: "3.0.0",
    // optional
    timeout: 5000
});

github.authenticate({
    type: "oauth",
    token: token
});

/*
 * GET home page.
 */

exports.index = function(req, res){
    res.render('index', { title: 'Visual Feature' });
};

exports.dashboard = function(req, res) {
    // github.user.get({}, function(err, usr) {
    //     console.log("GOT ERR?", err);
    //     console.log("GOT RES?", usr);
    
    //     // github.repos.getAll({}, function(err, res) {
    //     //     console.log("GOT ERR?", err);
    //     //     console.log("GOT RES?", res);
    //     // });
    // });
    res.render('dashboard', { title: 'Feature Way' });
};