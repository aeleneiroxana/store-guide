const express = require('express');
const app = express();
const morgan = require('morgan');

const liderboardRoutes = require('./api/routes/liderboards');

// Routes which should handle requsts

app.use(morgan('dev'));

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