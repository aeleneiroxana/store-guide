const express = require('express')
const router = express.Router()

router.get('/', (req, res, next) => {
    //! Here we should add functionality
    const list = req.body.list
    console.log(list)
    
    //! Here we are calling Vlad's function with the list parameter
    //! And we just return a response with 100 scrambled words which is the outpuit of the called function
    res.status(201).json({
        message: 'Handling POST requsts to /home',
        words: {
            ceva: 'dsds'
        }
    });
});

router.post('/', (req, res, next) => {
    res.status(200).json({
        message: 'Handling POST requsts to /home',

    });
});

module.exports = router;
