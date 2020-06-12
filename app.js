const express = require('express');
const app = express();
const morgan = require('morgan');
const bodyParser = require('body-parser');

const homeRoute = require('./api/routes/home')
const liderboardRoutes = require('./api/routes/liderboards');

// Routes which should handle requsts

app.use(morgan('dev'));
app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());

app.use('/home', homeRoute)
app.use('/liderboards', liderboardRoutes);
// app.use('/', (req, res, next) => {
//     res.status(200).json({
//         message: 'It works!'
//     });
// });

app.use((req, res, next) => {
    const error = new Error('Not found');
    error.status = 404;
    next(error);
});

app.use((error, req, res, next) => {
   res.status(error.status || 500);
   res.json({
       error: {
           message: error.message
       }
   })
});


module.exports = app;
