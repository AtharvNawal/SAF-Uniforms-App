// Dev Firebase web config for the SAF Uniforms Admin Portal.
//
// Replace the two PLACEHOLDER values with the apiKey + appId shown in
// Firebase Console → Project settings → Your apps → Web app
// (after registering a new Web app on the `saf-uniforms` project).
//
// The other values are fixed by the Firebase project itself and match
// the existing mobile app config (see lib/firebase_options.dart).

export const environment = {
  production: false,
  firebase: {
    apiKey: 'AIzaSyDPhMOLaWLXix-nDjzgJ7UpM4-_SWkbNuM',
    authDomain: 'saf-uniforms.firebaseapp.com',
    projectId: 'saf-uniforms',
    storageBucket: 'saf-uniforms.firebasestorage.app',
    messagingSenderId: '612500938654',
    appId: '1:612500938654:web:51326bced812a7965e408f',
  },
  functionsRegion: 'asia-southeast1',
};
