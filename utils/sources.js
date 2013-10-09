var GitHubApi = require("github");
var github = new GitHubApi({ version: "3.0.0", timeout: 5000 });

//  branch - name of the branch to clean
//  default - name of the master to reset environment to

exports.resetEnvironment = function (branch, persistCommits, default) {
	github.events.getFromRepo(
        {
            user: "Naviam",
            repo: "VisualFeature"
        },
        function(err, res) {
            console.log(err);
            console.log(res);
        }
    );
}