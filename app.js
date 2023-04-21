// Copyright 2017 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

'use strict';

// [START gae_flex_quickstart]
const express = require('express');
const authRoute = require('./authRoute.js');

const app = express();

app.get('/', (req, res) => {
  console.log("regular request body: " + req.body);
  res.status(200).send('Hello, Team!').end();
});

app.use('/auth', authRoute);

app.get('*', (req, res) => {
  res.status(400).send("Sorry, this is an invalid URL");
});

/*app.use('/', (req,res,next)=>{ // example of middleware functions
  res.status(200).send("The next method is being used on a subroute of things!");
  next();
})*/

// Start the server
const PORT = parseInt(process.env.PORT) || 8080;
app.listen(PORT, () => {
  // function is called when the server start listening for requests
  console.log(`App listening on port ${PORT}`);
  console.log('Press Ctrl+C to quit.');
});
// [END gae_flex_quickstart]

module.exports = app;
