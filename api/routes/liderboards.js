const express = require('express')
const router = express.Router()

router.get('/', (req, res, next) => {
    res.status(200).json({
        message: 'Handling GET requsts to /liderboards'
    });
});

router.post('/', (req, res, next) => {
    res.status(200).json({
        message: 'Handling POST requsts to /liderboards'
    });
});

module.exports = router;
