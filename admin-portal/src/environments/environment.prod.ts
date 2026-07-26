// Production Firebase web config for the SAF Uniforms Admin Portal.
//
// Same Firebase project as the dev config — the admin portal has no
// separate prod project. Keeping a distinct file is forward-looking so
// a future env split (staging vs prod) can land without restructuring.

export const environment = {
  production: true,
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
