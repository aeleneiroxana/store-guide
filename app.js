const express = require('express');
const app = express();

const liderboardRoutes = require('./api/routes/liderboards');

app.use((req, res, next) => {
    res.status(200).json({
        message: 'It works!'
    });
});

app.use('/liderboards', liderboardRoutes);

module.exports = app;