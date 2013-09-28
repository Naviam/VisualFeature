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
    github.user.get({}, function(err, usr) {
        github.user.getOrgs({}, function(err, orgs) {
            console.log(err);
            res.render('dashboard', { title: 'Feature Way', user: usr, orgs: orgs });
        });
    });
};

exports.repositories = function(req, res) {
    // console.log("GOT RES?", orgs);
    var orgName = req.params.org;
    console.log("get repos for org: " + orgName);
    github.repos.getFromOrg({org: orgName}, function (err, repos) {
        console.log("get from org error: " + err);
        res.json(repos);
    });
};

exports.stories = function (req, res) {
    var repoName = req.params.repo;
    var owner = req.params.owner;
    console.log("get stories for repo: " + repoName + " and owner: " + owner);
    github.pullRequests.getAll({ user: owner, repo: repoName }, function (err, stories) {
        console.log("get stories from repo error: " + err);
        res.json(stories);
    });
};