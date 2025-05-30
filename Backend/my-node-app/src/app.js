const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const setRoutes = require('./routes/index');

// Create data directory if it doesn't exist
const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir);
}

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// Set up routes
setRoutes(app);

// Root route
app.get('/', (req, res) => {
    res.json({
        message: 'IOT API is running',
        version: '1.0.0',
        database: 'Firebase',
        timestamp: new Date().toISOString(),
        availableEndpoints: {
            devices: {
                list: 'GET /api/devices',
                create: 'POST /api/devices',
                getOne: 'GET /api/devices/:deviceId',
                update: 'PUT /api/devices/:deviceId',
                delete: 'DELETE /api/devices/:deviceId'
            },
            sensorData: {
                add: 'POST /api/sensor-data',
                getForDevice: 'GET /api/sensor-data/:deviceId',
                getLatest: 'GET /api/latest-readings'
            },
            system: {
                health: 'GET /health',
                docs: 'GET /'
            }
        }
    });
});

// 404 handler - deve vir depois de todas as outras rotas
app.use((req, res) => {
    console.log(`404 - Route not found: ${req.method} ${req.url}`);
    res.status(404).json({
        error: 'Route not found',
        message: 'The requested endpoint does not exist. Please check the documentation at the root endpoint (GET /) for available routes.',
        requestedUrl: req.url,
        method: req.method
    });
});

// Error handling middleware
const errorHandler = (err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({ 
        error: 'Internal server error',
        message: err.message
    });
};

// Add error handler
app.use(errorHandler);

// Initialize server
const startServer = async () => {
    try {
        // Importa o serviço do Firebase para garantir que seja inicializado
        const firebaseService = require('./services/firebase.service');
        
        app.listen(PORT, () => {
            console.log(`Server is running on http://localhost:${PORT}`);
            console.log('Available routes:');
            console.log('- GET /');
            console.log('- GET /health');
            console.log('- GET /api/devices');
            console.log('- POST /api/devices');
            console.log('- GET /api/devices/:deviceId');
            console.log('- PUT /api/devices/:deviceId');
            console.log('- DELETE /api/devices/:deviceId');
            console.log('- POST /api/sensor-data');
            console.log('- GET /api/sensor-data/:deviceId');
            console.log('- GET /api/latest-readings');
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
};

startServer();