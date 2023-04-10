// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started

// The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
const functions = require('firebase-functions');
const os = require('os');
const path = require('path');
const fs = require('fs'); 

// The Firebase Admin SDK to access Firestore.
const admin = require('firebase-admin');
admin.initializeApp({
  // NEED TO REMEMBER TO CHANGE EMULATION BUCKET TO PRODUCTION BUCKET!!!
  //storageBucket: "gs://antisomnus-381222.appspot.com/", // emulation bucket
  storageBucket: "gs://antisomnus-bucket", // Deployment bucket
});

let writeToBucket = function(filePath, userId){ // Works BUT must initialize app to the RIGHT bucket for each environment

  if(filePath == null){
    console.log("The filepath was null!");
    return;
  }

  // writes file to temporary cloud function instance storage and uploads to bucket
  const storage = admin.storage();
  let destination = `dash_reports/${userId}/report.csv`;

  return storage
      .bucket()
      .upload( filePath, { destination } )
      .then( () => {console.log("sucessfully uploaded file to bucket"); /*fs.unlinkSync(filePath)*/} ) // DO NOT DELETE FILE. does not execute synchronously
      .catch(err => console.error('ERROR inside upload: ', err) );

}

let writeToCSV = function(data, userId){

  let tempPath = path.join(os.tmpdir(), `${userId}.csv`)
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

exports.getUserData = functions.https.onRequest(async (req, res) => { // returns JSON object of user's data in firestore for specified userID

    // firebase emulator test ID: pDElawFtvufKVcfItl6m
    let monthsDataKeys; // A list of keys for the doc.data() objects returnes
    let monthsString = ``;
    let monthsDataString = ``;
    let monthCount = -1; // keep index for months

    const userId = req.query.id; // should be in format: http://......../antisomnus-381222/......./getUserData?id=pDElawFtvufKVcfItl6m

    if(!userId || userId == ""){
      return res.send("Error: no User if Present");
    }

    await admin.firestore().collection('users').doc(userId).collection('data').get().then(snapshot => { // retrieve firestore data and format as JSON response

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

      let path = writeToCSV(JSONObject, userId);
      writeToBucket(path,userId);
      //fs.unlinkSync(path) // DO NOT EXECUTE. does not execute synchronously

      res.json(JSONObject); 
      return "";

    }).catch(reason => {
      res.send(reason);
    })

  });