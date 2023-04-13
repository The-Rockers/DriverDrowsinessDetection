// ?data={googleUser ID}-{fileType} // API request query format
// https://us-central1-antisomnus-381222.cloudfunctions.net/exportUserData?data=100242345133661897540-csv // example

// The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
const functions = require('firebase-functions');
const os = require('os');
const path = require('path');
const fs = require('fs'); 
const reader = require('xlsx');
const parquet = require('parquetjs');

// The Firebase Admin SDK to access Firestore.
const admin = require('firebase-admin');
admin.initializeApp({
  // NEED TO REMEMBER TO CHANGE EMULATION BUCKET TO PRODUCTION BUCKET!!!
  //storageBucket: "gs://antisomnus-381222.appspot.com/", // emulation bucket
  keyFilename: "./service-account.json",
  storageBucket: "gs://antisomnus-bucket", // Deployment bucket
});

let writeToBucket = function(filePath, userId, fileType){ // Works BUT must initialize app to the RIGHT bucket for each environment

  if(filePath == null){
    console.log("The filepath was null!");
    return;
  }

  // writes file to temporary cloud function instance storage and uploads to bucket

  var type;

  switch(fileType){
    case "CSV":
      type = "csv";
      break;

    case "XLS":
      type = "xlsx";
      break;

    case "PRQ":
      type = "parquet"; // parquet file not currently supported
      break;
  }

  const storage = admin.storage();
  let destination = `dash_reports/${userId}/report.${type}`;
  let url = [];

  storage.bucket()
  .upload( filePath, { destination } )
  .then( () => {console.log("sucessfully uploaded file to bucket"); /*fs.unlinkSync(filePath)*/} ) // DO NOT DELETE FILE. does not execute synchronously
  .catch(err => console.error('ERROR inside upload: ', err) );

  let expireTime = new Date();

  return new Promise( function (resolve, reject){
    storage.bucket().file(destination).getSignedUrl({
      action: 'read',
      expires: expireTime.setMinutes(expireTime.getMinutes() + 5), // will be valid for 5 minutes
    }).then(signedUrls => {
      console.log("Returning URL from writeToBucket: " + signedUrls[0]); // Works in production environment
      resolve(signedUrls[0]);
    });
  });

  //return url[0]; // have to wait until signed URL is generated by the promise

}

let writeToCSV = function(data, userId){

  let tempPath = path.join(os.tmpdir(), `${userId}.csv`);
  let outputString = `Month, Week, Day 1, Day 2, Day 3, Day 4, Day 5, Day 6, Day 7 \n`;

  //console.log("DATA: " + data);

  let months = Object.keys(data); // months
  //console.log("months: " + months);

  months.forEach((month) => {
    let weeks = Object.keys(data[month]); // weeksStarts
    //console.log("weeks: " + weeks); 

      weeks.forEach((week) => {
        let values = data[month][week]
        let temp = [];

        for(let i = 0; i < 7; i++){
          if(!values[i]){
            temp.push(0);
          }
          else{
            temp.push(values[i]);
          }
        }

        outputString += `${month},${week},${temp}\n`;
        //console.log("data: " + values);
      });
  });

  try {
      //fs.appendFileSync(`./antisomnus_data${userId}.csv`, outputString); // works on local but not on GCP

      console.log("trying to write to file");
      fs.writeFileSync(tempPath, outputString); // write file INSTEAD of appending it
      //fs.appendFileSync(tempPath, outputString); // temporarily stop writing to the file
      console.log("written to file");
      return tempPath;
      
  } catch (err) {
      console.error(err);
  }

  //return `./antisomnus_data${userId}.csv`; // returns the file path to the new file // works on local but not GCP
  console.log("Returning filepath from writetocsv: " + tempPath);
  return null; // moving this code into the block with fs.appendFileSync (above) works BUT it does not write to file. Moving it down here writes to file but does not sent it to storage?

}

let writeToExcel = function(data, userId){ // needs to be properly tested before being deployed

  // it expects an array of objects of this format
  // let testObj = {Month: "1-1-23", Week: "1-15-23", Day1: 5, Day2: 2, Day3: 6, Day7: 9}
  // JSON string should be in format '{"Month":"1-1-23","Week":"1-15-23","Day1":5,"Day2":2,"Day3":6,"Day7":9}'
  // run JSON parse on the String

  let tempPath = path.join(os.tmpdir(), `${userId}.xlsx`); // location and filename where file will be written to

  // data will be passed in a JSONObject
  var outputString = ``;
  var tempJSONArray = [];
  var tempJSONObject;
  var months = Object.keys(data); // returns the keys to the JSON object (which are months)

  months.forEach((month) => {
    let weeks = Object.keys(data[month]); // weeksStarts

      weeks.forEach((week) => {
        outputString = `{"Month": "${month}", "Week": "${week}",`;

        let values = data[month][week]
        let temp = [];

        for(let i = 0; i < 7; i++){
          if(!values[i]){
            outputString += `"Day${i+1}":${0}`;
          }
          else{
            outputString += `"Day${i+1}":${values[i]}`;
          }
          if(i === 6){
            outputString += ``;
          }
          else{
            outputString += `,`;
          }
          
        }

        outputString += `}\n`; 

        try{
        tempJSONObject = JSON.parse(outputString); // fails at this line
        } catch (e) {
          console.log("error: " + e);
        }
        tempJSONArray.push(JSON.parse(outputString));

        // '{"Month":"1-1-23","Week":"1-15-23","Day1":5,"Day2":2,"Day3":6,"Day7":9}'
        // Parse that object and push to teampJSONArray

      });
  });

  //tempJSONArray.push(data);

  const ws = reader.utils.json_to_sheet(tempJSONArray); // Very nifty method!
  const wb = reader.utils.book_new();

  reader.utils.book_append_sheet(wb,ws,"data");
  reader.writeFile(wb, tempPath);

  return tempPath;

}

let writeToParquet = async function(data, userId){

  var schema = new parquet.ParquetSchema({
    Month: { type: 'UTF8' },
    Week: { type: 'UTF8' },
    Day1: { type: 'INT64' },
    Day2: { type: 'INT64' },
    Day3: { type: 'INT64' },
    Day4: { type: 'INT64' },
    Day5: { type: 'INT64' },
    Day6: { type: 'INT64' },
    Day7: { type: 'INT64' },
  });

  let tempPath = path.join(os.tmpdir(), `${userId}.parquet`)
  let writer = await parquet.ParquetWriter.openFile(schema, tempPath);

  var outputString = ``;
  var tempJSONArray = [];
  var tempJSONObject;
  var months = Object.keys(data); // returns the keys to the JSON object (which are months)

  months.forEach((month) => {
    let weeks = Object.keys(data[month]); // weeksStarts

      weeks.forEach((week) => {
        outputString = `{"Month": "${month}", "Week": "${week}",`;

        let values = data[month][week]

        for(let i = 0; i < 7; i++){
          if(!values[i]){
            outputString += `"Day${i+1}":${0}`;
          }
          else{
            outputString += `"Day${i+1}":${values[i]}`;
          }
          if(i === 6){
            outputString += ``;
          }
          else{
            outputString += `,`;
          }
          
        }

        outputString += `}\n`; 

        try{
        tempJSONObject = JSON.parse(outputString);
        } catch (e) {
          console.log("error: " + e);
        }

        tempJSONArray.push(JSON.parse(outputString));

      });
  });


  for(let i = 0; i < /*tempJSONArray.length*/ 20; i++){
   try{
    await writer.appendRow(tempJSONArray[i]);
    //await writer.appendRow({Month: '1-1-23', Week: '1-1-23', Day1: 1, Day2:3, Day3:3, Day4:5, Day5:6, Day6:8, Day7:57});
   } catch (e){
    console.log("Error: " + e);
   }
  }

  await writer.close();
  return tempPath;

}

exports.exportUserData = functions.https.onRequest(async (req, res) => { // returns JSON object of user's data in firestore for specified userID

    res.header('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Origin', '*'); // set access control so all sites can call API without receiving CORS errors

    // firebase emulator test ID: pDElawFtvufKVcfItl6m
    let monthsDataKeys; // A list of keys for the doc.data() objects returnes
    let monthsString = ``;
    let monthsDataString = ``;
    let monthCount = -1; // keep index for months

    const query = req.query.data; // inject information to API in format ?data={googleUser ID}-{fileType}
    const queryData = query.split("-");
    const userId = queryData[0];
    const fileType = queryData[1].toUpperCase(); // CSV, PRQ, XLS, 
    //const userId = req.query.data; // should be in format: http://......../antisomnus-381222/......./getUserData?id=pDElawFtvufKVcfItl6m
    //const fileType = req.query.type; 

    console.log("User ID in request query: " + userId);
    console.log("File type in request query: " + fileType);

    if(!(fileType == "CSV" || fileType == "PRQ" || fileType == "XLS")){
      return res.send("Error: Invalid file type entered. Supported types are CSV, PRQ, or XLS");
    }

    if(queryData.length != 2){
      return res.send("Error: Incorrect number of vars or format. Expected format \"?data=id-type\"");
    }

    if(!userId || userId == ""){
      return res.send("Error: no User is Present");
    }

    await admin.firestore().collection('users').doc(userId).collection('data').get().then(async snapshot => { // retrieve firestore data and format as JSON response

      let JSONResponseText = `{`;

      snapshot.forEach( (doc) => { // each document is 1 month

        monthCount++; // workaround for invalid index (foreach index returned invalid when accessed)
        monthsString = `${doc.id}`; // retrieves the month

        JSONResponseText += `"${monthsString}":`;
        JSONResponseText += `{`;

        monthsDataKeys = Object.keys(doc.data()); // retrieves the months attributes for each document
        monthsDataKeys.forEach( (key,index) => { // for each week in the month

          monthsDataString = ``; // reset monthsDataString for each week's data
          monthsDataString += `${doc.data()[key]}`;

          JSONResponseText += `"${key}":`

          if(index === monthsDataKeys.length-1){ // if on last weekStart fields
            JSONResponseText += `[${monthsDataString}]`; // no comma
          }
          else{
            JSONResponseText += `[${monthsDataString}],`; // add comma for next element
          }

        }); // returns data for each key in month

        if(monthCount === snapshot.size-1){ // if on last month
          JSONResponseText += `}`; // no comma
        }
        else{
          JSONResponseText += `},`; // comma
        }

      });

      JSONResponseText += '}';

      let JSONObject = JSON.parse(JSONResponseText);
      //console.log(JSONObject);

      //     if(!(fileType == "CSV" || fileType == "PRQ" || fileType == "XLS")){

      var path = "";

      switch(fileType){
        case "CSV":
          path = writeToCSV(JSONObject, userId);
          break;

        case "XLS":
          path = writeToExcel(JSONObject, userId);
          break;

        case "PRQ":
          path = await writeToParquet(JSONObject, userId);
          break;
      }

      //let path = writeToExcel(JSONObject, userId); // write to excel file testing
      //let path = writeToCSV(JSONObject, userId);
        writeToBucket(path,userId, fileType).then((signedURL) => {
        console.log("Returned signed URL from writeToBucket: " + signedURL);

        let signedURLJSON = `{"url" : "${signedURL}"}`; // return signed URL as JSON
        
        res.header('Access-Control-Allow-Origin', '*');
        res.set('Access-Control-Allow-Origin', '*');
        res.send(JSON.parse(signedURLJSON));
        //res.send(`${signedURL}`);
      });

      console.log("Finished sending signed URL!");

    }).catch(reason => {
      res.send(reason);
    })

  });