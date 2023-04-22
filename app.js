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
const {Storage} = require('@google-cloud/storage');

const app = express();
const storage = new Storage({
  projectId: 'antisomnus-381222',
  storageBucket: "gs://antisomnus-bucket", // Deployment bucket
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

app.get('/data/getLists', async (req,res)=>{
  // /data/getLists?userId=100242345133661897540 (example route)

  if(!req.query.userId){
    res.status(404).send("Invalid userID");
  }
  else{

    let userId = req.query.userId;
    let videoFiles = [];
    let predictionFiles = [];
    let userVidDest = `users/${userId}/prediction_data/`;
    let userPredDest = `users/${userId}/video_data/`;

    // '{"names":["en_model_v0.h5"], "testVals": [1,2,3,4,5]}'
    let JSONResponse = `'{"videoFiles":[`;
  
    await storage.bucket("antisomnus-bucket").getFiles({ prefix: userVidDest, autoPaginate: false }).then((files)=>{
  
      files[0].forEach((element) => {
        videoFiles.push(element.name.substring(userVidDest.length, element.length));
      });
  
    });

    await storage.bucket("antisomnus-bucket").getFiles({ prefix: userPredDest, autoPaginate: false }).then((files)=>{
  
      files[0].forEach((element) => {
        predictionFiles.push(element.name.substring(userPredDest.length, element.length));
      });
  
    });

    videoFiles.forEach((name, index)=>{

      if(name.length != 0){ //Remves the extra file with no name
  
        if(index < videoFiles.length -1){
          JSONResponse += `"${name}",`; // comma
        }
        else{
          JSONResponse += `"${name}"`; // no comma
        }
  
      }
  
    });

    JSONResponse += `], "predictionFiles":[`;

    predictionFiles.forEach((name, index)=>{

      if(name.length != 0){ //Remves the extra file with no name
  
        if(index < predictionFiles.length -1){
          JSONResponse += `"${name}",`; // comma
        }
        else{
          JSONResponse += `"${name}"`; // no comma
        }
  
      }
  
    });

    JSONResponse += `]}'`;

    //console.log(JSONResponse);
    res.status(200).send(JSONResponse);
  }

});

app.post('/data/send', (req,res)=>{
  console.log("receiving data....");
  res.status(200).send("receiving data...");
});

app.get('/model/getName', async (req,res)=>{ // retrieve the list of names of models stored
  
  let models = [];
  let destination = `models/`;
  let JSONResponse = `'{"names":[`;

  await storage.bucket("antisomnus-bucket").getFiles({ prefix: 'models/', autoPaginate: false }).then((files)=>{

    files[0].forEach((element) => {
      models.push(element.name.substring(destination.length, element.length));
    });

  });

  models.forEach((name, index)=>{

    if(name.length != 0){ //Remves the extra file with no name

      if(index < models.length -1){
        JSONResponse += `"${name}",`; // comma
      }
      else{
        JSONResponse += `"${name}"`; // no comma
      }

    }

  });

  JSONResponse += `]}'`;

  res.status(200).send(JSONResponse);

});

app.get('/model/retrieve', (req,res)=>{

  // /model/retrieve?name={model name} follow this format for querying

  if(!req.query.name){
    res.status(404).send("Invalid model name.");
  }
  else{ // send signed URL as JSON response

    let fileName = req.query.name;
    let destination = `models/${fileName}`;
    let expireTime = new Date();
    let JSONResponse = `'{"url":"`;

    storage.bucket('antisomnus-bucket').file(destination).getSignedUrl({
      action: 'read',
      expires: expireTime.setMinutes(expireTime.getMinutes() + 10), // will be valid for 5 minutes
    }).then(signedUrls => {
      let url =  signedUrls[0];
      JSONResponse += `${url}"}'`;
      res.status(200).send(JSONResponse);
    });

  }

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
