function pageState() {
    this.githubLogin = null;
    this.repository = null;
    this.organization = null;
}

function organization(org) {
    var self = this;
    self.login = org.login;

    self.repositories = ko.observableArray();

    self.getRepositories = function (org) {
        $.getJSON("/repositories/" + org, function(data) {
            self.repositories(data);
        });
    };
    self.getRepositories(self.login);
}

function repository(repo) {
    var self = this;
    self.name = ko.observable(repo.name);
    self.owner = ko.observable(repo.owner.login);
    self.stories = ko.observableArray();

    self.getCompletedStories = function (ownerName, repoName) {
        $.getJSON("/stories/" + ownerName + "/" + repoName, function(data) {
            self.stories(data);
        });
    };
    self.getCompletedStories(self.owner(), self.name());
}

function AppViewModel(model) {
    var self = this;

    //self.state = ko.observable(pageState());

    self.user = ko.observable(model.user);
    self.currentRepository = ko.observable();
    self.organizations = ko.observableArray();
    for (var org in model.orgs) {
        self.organizations.unshift(new organization(model.orgs[org]));
    }

    self.setCurrentRepository = function (repo) {
        self.currentRepository(new repository(repo));
    }
}