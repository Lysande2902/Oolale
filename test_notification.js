// Script para probar notificaciones push de Firebase
// Uso: node test_notification.js

const https = require('https');

// IMPORTANTE: Reemplaza esto con tu Server Key de Firebase
// Lo encuentras en: Firebase Console → Project Settings → Cloud Messaging → Server Key
const SERVER_KEY = 'TU_SERVER_KEY_AQUI';

// Token FCM del dispositivo
const FCM_TOKEN = 'e87lBJ7aRWGMS_J8QE7z9b:APA91bEDo0gpdLx8XSR9Kh09bsOsvRzFKevp9iiVgD0-3zdPsrtzugmO9GDcTRzB0ac6yNwn7NZBv-9i12kbCwnFex6Cyjh2bzTRCMsRS3mFwkdpRVURCkAU';

const payload = JSON.stringify({
  to: FCM_TOKEN,
  notification: {
    title: 'Prueba Óolale',
    body: 'Esta es una notificación de prueba desde Node.js',
    sound: 'default',
    priority: 'high'
  },
  data: {
    type: 'test',
    message: 'Notificación de prueba'
  },
  priority: 'high'
});

const options = {
  hostname: 'fcm.googleapis.com',
  port: 443,
  path: '/fcm/send',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `key=${SERVER_KEY}`,
    'Content-Length': Buffer.byteLength(payload)
  }
};

console.log('📤 Enviando notificación push...');
console.log('Token:', FCM_TOKEN);

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('\n✅ Respuesta de Firebase:');
    console.log('Status:', res.statusCode);
    console.log('Body:', data);
    
    if (res.statusCode === 200) {
      console.log('\n🎉 Notificación enviada exitosamente!');
    } else {
      console.log('\n❌ Error al enviar notificación');
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error);
});

req.write(payload);
req.end();
