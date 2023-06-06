'use strict';

const express = require('express');
const {Storage} = require('@google-cloud/storage');
const multer = require('multer');  
// const { OAuth2Client } = require('google-auth-library');
const firebaseAdmin = require('firebase-admin');
// const firebaseAdminClientIds = require('./firebaseClient');

const path = require('path');
const fs = require('fs'); 
const os = require('os');
const url = require('url');

const app = express();
// const client = new OAuth2Client();

// Access to storage bucket
const storage = new Storage({
  projectId: 'antisomnus-381222',
  storageBucket: "gs://antisomnus-bucket", // Deployment bucket
  keyFilename: './keyfile.json'
});

// access to firebase admin SDK for JWT authentication
const serviceAccount = require('./keyfile2.json');
const firebaseClient = firebaseAdmin.initializeApp({
  credential: firebaseAdmin.credential.cert(serviceAccount)
});

async function verifyIdToken(idToken) {

  try{
    const payload = await firebaseAdmin.auth().verifyIdToken(idToken);
    // console.log(payload);
    return payload;
  } catch (error){
    console.error('Error verifying ID token:', error);
    return null;
  }

}

app.get('/', (req, res) => {
  console.log("Hello, Team!");
  res.status(200).send('Hello, Team!').end();
});

app.get('/data/getLists', async (req,res)=>{
  // /data/getLists?userId=KlbEZkEFuxZqbY3qPijHdrROeks1 (example route)

  /*
    Note that the userId must be specified in the http request AND in a 
    JWT must be included in the header of the http request in the format
    of {"JWT": '{insert-JWT-here}' }
  */

  let jwt = req.headers.jwt;
  let payload = await verifyIdToken(jwt);
  let uid = payload.uid;

  if(!req.query.userId){
    res.status(403).send("Invalid userID");
    return;
  }
  else if(req.query.userId != uid){
    res.status(403).send("userId and JWT mismatch. Authentication failed!");
    return;
  }
  else{

    let userId = req.query.userId;
    let videoFiles = [];
    let predictionFiles = [];
    let userVidDest = `users/${userId}/video_data/`;
    let userPredDest = `users/${userId}/prediction_data/`;

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

app.post('/data/send', async (req,res)=> {

  // /data/send?userId=KlbEZkEFuxZqbY3qPijHdrROeks1&type=csv (example endpoint request)

  /*
    Note that the userId must be specified in the http request AND in a 
    JWT must be included in the header of the http request in the format
    of {"JWT": '{insert-JWT-here}' }
  */

  let jwt = req.headers.jwt;
  let payload = await verifyIdToken(jwt);
  let uid = payload.uid;

  if(!req.query.userId){
    res.status(403).send("Invalid userID");
    return;
  }
  else if(req.query.userId != uid){
    res.status(403).send("userId and JWT mismatch. Authentication failed!");
    return;
  }

  const queryData = url.parse(req.url, true).query;

  if(Object.keys(queryData).length != 2){

    res.status(404).send("Error: Incorrect number of params in query. Expected format \"?userId={userID}&type={fileType}\"");
    return;

  }
  else{

    let type;
    const userId = queryData.userId;
    let fileType = queryData.type.toUpperCase();
    let tempPath;
    let originalFileName;

    if(fileType === "CSV" || fileType === "PARQUET"){ // Will only accept CSV & parquet files for prediction data...
      type = "prediction_data";
    }
    else if(fileType === "AVI" || fileType === "MP4"){ // Will only accept AVI and MP4 files for prediction data
      type = "video_data";
    }
    else{
      res.status(404).send("Error: Unsupported file format " + fileType);
      return;
    }

    tempPath = path.join(os.tmpdir(), `/${userId}/${type}/`);

    if(!fs.existsSync(tempPath)){
      fs.mkdirSync(tempPath, { recursive: true });
    }

    var localStorage = multer.diskStorage({ 
      destination: function (req, file, callback) {  
        callback(null, tempPath);
      },  
      filename: function (req, file, callback) {  
        originalFileName = file.originalname;
        tempPath += originalFileName;
        callback(null, file.originalname);  
      }  
    });

    var upload = multer({ storage : localStorage}).single('file');
    
    upload(req,res,async function(err){
      if(err){
        res.send("Error uploading file.");
        return;
      }
      else{

        const bucketDestination = `users/${userId}/${type}/${originalFileName}`;

        console.log("Bucket dest: " + bucketDestination);
        console.log("Temp path: " + tempPath);

        const options = {
          destination: bucketDestination,
          //preconditionOpts: {ifGenerationMatch: 0}, // unecessary attribute
        };

        await storage.bucket("antisomnus-bucket").upload(tempPath, options)
        .catch(err => console.error('ERROR inside upload: ', err) );

        res.send("file Uploaded successfully!");  
      }
    });

    console.log("receiving data....");
    //res.status(200).send("receiving data...");
  }

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

  // /model/retrieve?name={model name} (endpoint example)

  if(!req.query.name){
    res.status(404).send("Invalid model name.");
    return;
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

module.exports = app;
