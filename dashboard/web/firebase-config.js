// Replace these values with your actual Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyAu9O3rc9wznjy6eiFaZFiFZOGQBBsjnt8",
  authDomain: "health-tracker-zw.firebaseapp.com",
  projectId: "health-tracker-zw",
  storageBucket: "health-tracker-zw.firebasestorage.app",
  messagingSenderId: "557640477933",
  appId: "1:557640477933:web:c5016117b0c6abfe5b70e4"
};

// Initialize Firebase
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js';
import { getFirestore } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore.js';

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

export { db };