const { initializeApp } = require('firebase/app');
const { 
    getFirestore, 
    collection, 
    getDocs, 
    limit, 
    query,
    setLogLevel,
    enableNetwork,
    initializeFirestore
} = require('firebase/firestore');

// Habilitar logs detalhados do Firestore
setLogLevel('debug');

const firebaseConfig = {
    apiKey: "AIzaSyCPps7eUmr_TvU7vwmzxnlZ9L2b1d1UkKU",
    authDomain: "iot-progdispmoveis2.firebaseapp.com",
    projectId: "iot-progdispmoveis2",
    storageBucket: "iot-progdispmoveis2.appspot.com",
    messagingSenderId: "766911646385",
    appId: "1:766911646385:web:e955d518a01f50cc9ef090",
    measurementId: "G-YZNM9SNG3T"
};

// Initialize Firebase
console.log('Initializing Firebase...');
const app = initializeApp(firebaseConfig);

// Initialize Firestore with settings
console.log('Initializing Firestore with custom settings...');
const db = initializeFirestore(app, {
    experimentalForceLongPolling: true,
    useFetchStreams: false,
    ignoreUndefinedProperties: true
});

console.log('Firebase initialized, configuring Firestore...');

// Verificar conexão com o Firestore
const verifyConnection = async () => {
    console.log('Verifying Firestore connection...');
    
    try {
        // Habilita a rede explicitamente
        console.log('Enabling network...');
        await enableNetwork(db);
        
        // Tenta fazer uma consulta simples para verificar a conexão
        console.log('Testing query...');
        const testQuery = query(collection(db, 'devices'), limit(1));
        await getDocs(testQuery);
        console.log('✓ Firestore connection successful');
        return true;
    } catch (error) {
        // Se o erro for NOT_FOUND, significa que a coleção não existe, mas a conexão está ok
        if (error.code === 'not-found') {
            console.log('✓ Firestore connection successful (collection not found)');
            return true;
        }
        
        // Log detalhado do erro
        console.error('✗ Error details:', {
            code: error.code,
            message: error.message,
            stack: error.stack
        });

        if (error.code === 'permission-denied') {
            console.error('✗ Permission denied. Please check Firestore rules.');
        } else if (error.code === 'resource-exhausted') {
            console.error('✗ Resource exhausted. Please check your Firebase quota.');
        }

        return false;
    }
};

// Inicializar Firestore
const setupFirestore = async () => {
    try {
        console.log('Testing Firestore connection...');
        const isConnected = await verifyConnection();
        
        if (!isConnected) {
            throw new Error('Failed to connect to Firestore');
        }

        return {
            success: true,
            db: db
        };
    } catch (error) {
        console.error('Failed to initialize Firestore:', error);
        return {
            success: false,
            error: error.message
        };
    }
};

// Exportar as configurações
module.exports = { 
    db,
    verifyConnection,
    setupFirestore,
    app
}; 