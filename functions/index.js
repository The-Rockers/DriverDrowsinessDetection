// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started

// The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access Firestore.
const admin = require('firebase-admin');
admin.initializeApp();

// Take the text parameter passed to this HTTP endpoint and insert it into 
// Firestore under the path /messages/:documentId/original
exports.addMessage = functions.https.onRequest(async (req, res) => {

    let documents = [];
    let monthsDataKeys; // A list of keys for the doc.data() objects returnes
    let monthsString = ``;
    let monthsDataString = ``;
    let monthCount = -1; // keep index for months

    let item;
    // Grab the text parameter.
    //pDElawFtvufKVcfItl6m
    const userId = req.query.id;
    // Push the new message into Firestore using the Firebase Admin SDK.

    //const writeResult = await admin.firestore().collection('messages').add({original: original});
    await admin.firestore().collection('users').doc(userId).collection('data').get().then(snapshot => {

      //const json = '{"1-1-23": {"1-1-23":[1,2,3,4,5], "1-8-23":[6,5,4,3,2]}}'; // example JSON body
      // var test = `{"1-1-23":{"1-1-23":[1,2,3,4],"1-8-23":[1,2,3,45,6,7]}, "1-4-23":{"1-4-23":[1,2,3,45,6,71,2,3,4,5]}}` // This will work
      // vat test = `{"1-1-23":{"1-1-23":[1,2,3,4],"1-8-23":[1,2,3,45,6,7]}, "1-4-23":{"1-4-23":[1,2,3,45,6,71,2,3,4,5]},}`
      //const obj = JSON.parse(json);

      let JSONResponseText = `{`;

      snapshot.forEach( (doc) => { // each document is 1 month

        monthCount++; // workaround for invalid index (foreach index returned invalid when accessed)
        monthsString = `${doc.id}`; // retrieves the month

        JSONResponseText += `"${monthsString}":`;
        JSONResponseText += `{`;

        monthsDataKeys = Object.keys(doc.data()); // retrieves the months attributes for each document
        monthsDataKeys.forEach( (key,index) => {

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

      /*let JSONResponse = {
        months: monthsString,
        monthsData: monthsDataString
      };*/

      /*
        let text = '{ "employees" : [' +
        '{ "firstName":"John" , "lastName":"Doe" },' +
        '{ "firstName":"Anna" , "lastName":"Smith" },' +
        '{ "firstName":"Peter" , "lastName":"Jones" } ]}';
        */

      console.log(JSONResponseText);
      res.json(JSON.parse(JSONResponseText));
      return "";
    }).catch(reason => {
      res.send(reason);
    })
  });


/*

// Listens for new messages added to /messages/:documentId/original and creates an
// uppercase version of the message to /messages/:documentId/uppercase
exports.makeUppercase = functions.firestore.document('/messages/{documentId}')
.onCreate((snap, context) => {

  // Grab the current value of what was written to Firestore.
  const original = snap.data().original;

  // Access the parameter `{documentId}` with `context.params`
  functions.logger.log('Uppercasing', context.params.documentId, original);
  
  const uppercase = original.toUpperCase();
  
  // You must return a Promise when performing asynchronous tasks inside a Functions such as
  // writing to Firestore.
  // Setting an 'uppercase' field in Firestore document returns a Promise.
  return snap.ref.set({uppercase}, {merge: true});
  
});

*/