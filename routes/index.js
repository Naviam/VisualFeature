
/*
 * GET home page.
 */

exports.index = function(req, res){
    res.render('index', { title: 'Visual Feature' });
};

exports.dashboard = function(req, res) {
    res.render('dashboard', { title: 'Feature Way' });
};