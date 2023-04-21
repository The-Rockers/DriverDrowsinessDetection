var express = require('express');
var app = express();
let router = express.Router();

/*

    It would be ideal to send the access token in the formt of {"AccessToken": "123..."},
    but for some reason express was not representing the sent JSON payload when requests
    were made either from the terminal with the curl command or from the browser with
    XMLHttpRequest.

*/

router.get("/:AccessToken", (req,res)=>{ // Retriving access token this ways
    console.log("auth request body: " + req.params.AccessToken);
    res.status(200).send("Access Token is: " + req.params.AccessToken);
});

module.exports = router;