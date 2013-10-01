function link (url, text, title) {
    this.url = url;
    this.text = text;
    this.title = title;
}

function findLinksInString(str) {
    geturl = new RegExp(
          "(^|[ \t\r\n])((ftp|http|https|gopher|mailto|news|nntp|telnet|wais|file|prospero|aim|webcal):(([A-Za-z0-9$_.+!*(),;/?:@&~=-])|%[A-Fa-f0-9]{2}){2,}(#([a-zA-Z0-9][a-zA-Z0-9$_.+!*(),;/?:@&~=%-]*))?([A-Za-z0-9$_+!*();/?:~-]))"
         ,"g"
       );

    return str.match(geturl) || "";
}

function organization(org) {
    var self = this;
    self.login = org.login;
    self.isCollapsed = ko.observable(false);

    self.repositories = ko.observableArray();

    self.toggleCollapse = function () {
        self.isCollapsed(!self.isCollapsed());
    };

    self.getRepositories = function (org) {
        $.getJSON("/repositories/" + org, function(data) {
            self.repositories(data);
            
            var found = jQuery.grep(self.repositories(), function(r) {
                // TODO: replace hardcoded name with user session variable
                return r.name == "VisualFeature";
            });
            if (found.length == 1) {
                window.viewmodel.setCurrentRepository(found[0]);
            }
        });
    };
    self.getRepositories(self.login);
}

function story(story) {
    var self = this;
    self.title = ko.observable(story.title);
    self.number = ko.observable(story.number);
    self.body = ko.observable(story.body);
    self.normalizedBody = ko.observable();
    self.html_url = ko.observable(story.html_url);

    self.links = ko.computed(function () {
        var links = findLinksInString(self.body());
        // TODO: remove links from description
        self.normalizedBody(self.body());
        for (var i in links) {
            self.normalizedBody(self.normalizedBody().replace(links[i], ""));
        }
        
        return links;
    });

    self.storyLinks = ko.computed(function () {
        var array = new Array();
        console.log(self.links());
        for (var index in self.links())
        {
            var lnk = self.links()[index];
            console.log(lnk);
            var text = lnk.substring(lnk.lastIndexOf('/') + 1);
            array.unshift(new link(lnk, text, text));
        }

        return array;
    });
}

function repository(repo) {
    var self = this;
    self.name = ko.observable(repo.name);
    self.owner = ko.observable(repo.owner.login);
    self.stories = ko.observableArray();

    self.getCompletedStories = function (ownerName, repoName) {
        $.getJSON("/stories/" + ownerName + "/" + repoName, function(data) {
            self.stories.removeAll();
            $.each(data, function (index, value) {
                self.stories.unshift(new story(value));
            });
            //self.stories(data);
        });
    };
    self.getCompletedStories(self.owner(), self.name());
}

function AppViewModel(model) {
    var self = this;

    self.user = ko.observable(model.user);
    self.currentRepository = ko.observable();
    self.organizations = ko.observableArray();
    for (var org in model.orgs) {
        self.organizations.unshift(new organization(model.orgs[org]));
    }

    self.setCurrentRepository = function (repo) {
        console.log(repo);
        self.currentRepository(new repository(repo));
    }
}