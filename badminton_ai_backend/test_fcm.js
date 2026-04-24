const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function test() {
  try {
    const response = await admin.messaging().send({
      notification: {
        title: 'Test',
        body: 'Testing Firebase Admin'
      },
      token: 'dummy_token' // Dĩ nhiên sẽ lỗi token, nhưng để check admin khởi tạo ok ko
    });
    console.log(response);
  } catch (error) {
    console.log("Error:", error.message);
  }
}
test();
