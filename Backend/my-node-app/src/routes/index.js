const express = require('express');
const firebaseService = require('../services/firebase.service');
const router = express.Router();

// Middleware para timeout
const timeout = (req, res, next) => {
    // Flag para controlar se a resposta já foi enviada
    let isResponseSent = false;

    // Configurar o timeout
    const timeoutId = setTimeout(() => {
        if (!isResponseSent) {
            isResponseSent = true;
            res.status(408).json({ 
                error: 'Request timeout',
                message: 'A operação demorou mais que o esperado. Por favor, tente novamente.'
            });
        }
    }, 30000);

    // Interceptar o método res.json para limpar o timeout
    const originalJson = res.json;
    res.json = function(data) {
        if (!isResponseSent) {
            clearTimeout(timeoutId);
            isResponseSent = true;
            return originalJson.call(this, data);
        }
    };

    next();
};

function setRoutes(app) {
    // Aplicar middleware de timeout em todas as rotas
    app.use(timeout);

    // Health check route
    app.get('/health', (req, res) => {
        res.json({ status: 'ok', timestamp: new Date().toISOString() });
    });

    // Rotas para Dispositivos
    app.post('/api/devices', async (req, res) => {
        try {
            const deviceId = await firebaseService.createDevice(req.body);
            res.json({ 
                message: 'Device created successfully',
                deviceId 
            });
        } catch (err) {
            console.error('Error creating device:', err);
            res.status(500).json({ error: err.message });
        }
    });

    app.get('/api/devices/:deviceId', async (req, res) => {
        try {
            const device = await firebaseService.getDevice(req.params.deviceId);
            if (!device) {
                return res.status(404).json({ error: 'Device not found' });
            }
            res.json(device);
        } catch (err) {
            console.error('Error fetching device:', err);
            res.status(500).json({ error: err.message });
        }
    });

    app.get('/api/devices', async (req, res) => {
        try {
            const devices = await firebaseService.getAllDevices();
            res.json(devices);
        } catch (err) {
            console.error('Error fetching devices:', err);
            res.status(500).json({ error: err.message });
        }
    });

    app.put('/api/devices/:deviceId', async (req, res) => {
        try {
            const success = await firebaseService.updateDevice(req.params.deviceId, req.body);
            if (!success) {
                return res.status(404).json({ error: 'Device not found' });
            }
            res.json({ message: 'Device updated successfully' });
        } catch (err) {
            console.error('Error updating device:', err);
            res.status(500).json({ error: err.message });
        }
    });

    app.delete('/api/devices/:deviceId', async (req, res) => {
        try {
            const success = await firebaseService.deleteDevice(req.params.deviceId);
            if (!success) {
                return res.status(404).json({ error: 'Device not found' });
            }
            res.json({ message: 'Device deleted successfully' });
        } catch (err) {
            console.error('Error deleting device:', err);
            res.status(500).json({ error: err.message });
        }
    });

    // Rotas para Dados dos Sensores
    app.post('/api/sensor-data', async (req, res) => {
        let timeoutHandle;
        
        try {
            // Validar os dados recebidos
            if (!req.body || !req.body.deviceId) {
                return res.status(400).json({
                    error: 'Invalid request',
                    message: 'deviceId é obrigatório'
                });
            }

            console.log('Recebendo dados do sensor:', req.body);
            
            const result = await firebaseService.addSensorData(req.body);
            
            console.log('Dados do sensor salvos com sucesso:', result);
            
            res.json({ 
                message: 'Sensor data added successfully',
                data: result
            });
        } catch (err) {
            console.error('Error adding sensor data:', err);
            if (!res.headersSent) {
                res.status(500).json({ 
                    error: 'Failed to add sensor data',
                    message: err.message 
                });
            }
        }
    });

    app.get('/api/sensor-data/:deviceId', async (req, res) => {
        try {
            const limit = parseInt(req.query.limit) || 100;
            const data = await firebaseService.getSensorData(req.params.deviceId, limit);
            res.json(data);
        } catch (err) {
            console.error('Error fetching sensor data:', err);
            res.status(500).json({ error: err.message });
        }
    });

    // Rota para últimas leituras
    app.get('/api/latest-readings', async (req, res) => {
        try {
            const readings = await firebaseService.getLatestReadings();
            res.json(readings);
        } catch (err) {
            console.error('Error fetching latest readings:', err);
            res.status(500).json({ error: err.message });
        }
    });

    // Rotas para Configurações
    app.get('/api/settings/:key', async (req, res) => {
        try {
            const setting = await db.getSetting(req.params.key);
            if (!setting) {
                return res.status(404).json({ error: 'Setting not found' });
            }
            res.json(setting);
        } catch (err) {
            console.error('Error fetching setting:', err);
            res.status(500).json({ error: err.message });
        }
    });

    app.put('/api/settings/:key', async (req, res) => {
        try {
            const { value, description } = req.body;
            const success = await db.updateSetting(req.params.key, value, description);
            if (!success) {
                return res.status(400).json({ error: 'Failed to update setting' });
            }
            res.json({ message: 'Setting updated successfully' });
        } catch (err) {
            console.error('Error updating setting:', err);
            res.status(500).json({ error: err.message });
        }
    });

    // Rota raiz com documentação das rotas disponíveis
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

    // Handler para rotas não encontradas
    app.use((req, res) => {
        res.status(404).json({
            error: 'Route not found',
            message: 'The requested endpoint does not exist. Please check the documentation at the root endpoint (GET /) for available routes.'
        });
    });

    // Handler para erros
    app.use((err, req, res, next) => {
        console.error('Unhandled error:', err);
        if (!res.headersSent) {
            res.status(500).json({
                error: 'Internal server error',
                message: err.message
            });
        }
    });
}

module.exports = setRoutes;