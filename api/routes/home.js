const express = require('express')
const router = express.Router()
const scramble = require('../../scrambleGen')


router.get('/', (req, res, next) => {
    res.status(201).json({
        message: 'Handling GET requsts to /home',
        words: {
            ceva: 'dsds'
        }
    });
});

router.post('/', (req, res, next) => {

     const list = req.body.list
     if(list){
         const scrambledList = scramble(list)
         console.log(scrambledList);
         
         res.status(201).json({
             message: 'Handling POST requsts to /home',
             list: scrambledList
         });
     }
});

module.exports = router;
