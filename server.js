const http = require('http');
const app = require('./app');

const port = process.env.PORT || 3000

const server = http.createServer(app);

server.listen(port, function(error) {
    if(error){
        console.log('Something went wrong', error)
    } else {
        console.log('Server is listening on port ' + port)
    }

})
