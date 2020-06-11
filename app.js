const express = require('express');
const app = express();

const liderboardRoutes = require('./api/routes/liderboards');

// Routes which should handle requsts

app.use((req, res, next) => {
    res.status(200).json({
        message: 'It works!'
    });
});

app.use('/liderboards', liderboardRoutes);

module.exports = app;