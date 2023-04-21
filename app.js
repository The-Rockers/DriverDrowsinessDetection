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
const Storage = require('@google-cloud/storage');

const app = express();
const storage = new Storage({
  projectId: 'antisomnus-381222',
  keyFilename: './keyfile.json'
});

app.get('/', (req, res) => {
  console.log("Hello, Team");
  res.status(200).send('Hello, Team!').end();
});

app.get('/auth/:AccessToken', (req, res) => {
  console.log("The access token was: " + req.params.AccessToken);
  res.status(200).send("Access token was: " + req.params.AccessToken);
});

app.get('/data/getList', (req,res)=>{
  console.log("Retrieving data list...");
  res.status(200).send("Retrieving data list");
});

app.post('/data/send', (req,res)=>{
  console.log("receiving data....");
  res.status(200).send("receiving data...");
});

app.get('/model/getName', (req,res)=>{
  console.log("Retrieving model name...");
  res.status(200).send("Retrieving model name");
});

app.get('/model/retrieve', (req,res)=>{
  console.log("Retrieving model...");
  res.status(200).send("Retrieving model...");
});

app.all('*', (req, res) => {
  res.status(400).send("Sorry, this is an invalid URL or HTTP method type");
});

// Start the server
const PORT = parseInt(process.env.PORT) || 8080;
app.listen(PORT, () => {
  // function is called when the server start listening for requests
  console.log(`App listening on port ${PORT}`);
  console.log('Press Ctrl+C to quit.');
});
// [END gae_flex_quickstart]

module.exports = app;
