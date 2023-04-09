// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started

// The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

exports.getUserData = functions.https.onRequest(async (req, res) => { // returns JSON object of user's data in firestore for specified userID

    // firebase emulator test ID: pDElawFtvufKVcfItl6m
    let monthsDataKeys; // A list of keys for the doc.data() objects returnes
    let monthsString = ``;
    let monthsDataString = ``;
    let monthCount = -1; // keep index for months

    const userId = req.query.id; // should be in format: http://......../antisomnus-381222/......./getUserData?id=pDElawFtvufKVcfItl6m

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

        console.log("index: " + monthCount);
        console.log("Snap length: " + snapshot.size);

        if(monthCount === snapshot.size-1){ // if on last month
          JSONResponseText += `}`; // no comma
        }
        else{
          JSONResponseText += `},`; // comma
        }

      });

      JSONResponseText += '}';

      res.json(JSON.parse(JSONResponseText));
      return "";

    }).catch(reason => {
      res.send(reason);
    })
  });