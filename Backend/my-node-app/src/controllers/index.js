class IndexController {
    getIndex(req, res) {
        res.send('Welcome to my Node.js application!');
    }
}

module.exports = IndexController;