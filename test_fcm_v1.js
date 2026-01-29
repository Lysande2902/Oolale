// Script para enviar notificaciones usando Firebase Cloud Messaging API V1
// Requiere: npm install googleapis

const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

// INSTRUCCIONES:
// 1. Ve a Firebase Console → Project Settings → Service Accounts
// 2. Click en "Generate new private key"
// 3. Guarda el archivo JSON como "service-account.json" en esta carpeta
// 4. Ejecuta: npm install googleapis
// 5. Ejecuta: node test_fcm_v1.js

// Token FCM del dispositivo (copia el token de los logs de Flutter)
const FCM_TOKEN = 'e87lBJ7aRWGMS_J8QE7z9b:APA91bEDo0gpdLx8XSR9Kh09bsOsvRzFKevp9iiVgD0-3zdPsrtzugmO9GDcTRzB0ac6yNwn7NZBv-9i12kbCwnFex6Cyjh2bzTRCMsRS3mFwkdpRVURCkAU';
const PROJECT_ID = 'oolale';

console.log('🔍 Usando token FCM:', FCM_TOKEN.substring(0, 50) + '...');

async function sendNotification() {
  try {
    // Buscar archivo de credenciales (puede tener cualquier nombre)
    let serviceAccountPath = path.join(__dirname, 'service-account.json');
    
    if (!fs.existsSync(serviceAccountPath)) {
      // Buscar archivos que empiecen con "oolale" y terminen con ".json"
      const files = fs.readdirSync(__dirname);
      const serviceAccountFile = files.find(f => f.startsWith('oolale') && f.endsWith('.json') && f !== 'package.json');
      
      if (serviceAccountFile) {
        serviceAccountPath = path.join(__dirname, serviceAccountFile);
        console.log(`✅ Encontrado archivo de credenciales: ${serviceAccountFile}`);
      } else {
        console.error('❌ Error: No se encontró el archivo de credenciales de Firebase');
        console.log('\n📝 Para obtenerlo:');
        console.log('1. Ve a: https://console.firebase.google.com/project/oolale/settings/serviceaccounts/adminsdk');
        console.log('2. Click en "Generate new private key"');
        console.log('3. Guarda el archivo en la carpeta oolale_mobile (no importa el nombre)');
        console.log('4. Ejecuta: npm install googleapis');
        console.log('5. Vuelve a ejecutar este script');
        return;
      }
    }

    const serviceAccount = require(serviceAccountPath);

    // Obtener token de acceso
    const jwtClient = new google.auth.JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging']
    });

    const tokens = await jwtClient.authorize();
    const accessToken = tokens.access_token;

    console.log('✅ Token de acceso obtenido');
    console.log('📤 Enviando notificación...');

    // Enviar notificación
    const message = {
      message: {
        token: FCM_TOKEN,
        notification: {
          title: 'Prueba Óolale',
          body: 'Esta es una notificación de prueba usando API V1'
        },
        data: {
          type: 'test',
          message: 'Notificación de prueba'
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channel_id: 'high_importance_channel'
          }
        }
      }
    };

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(message)
      }
    );

    const data = await response.json();

    if (response.ok) {
      console.log('\n🎉 ¡Notificación enviada exitosamente!');
      console.log('Message name:', data.name);
      console.log('\n📱 Revisa tu dispositivo Android y los logs de Flutter');
    } else {
      console.error('\n❌ Error al enviar notificación:');
      console.error('Status:', response.status);
      console.error('Response:', JSON.stringify(data, null, 2));
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

sendNotification();
