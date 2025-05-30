const mysql = require('mysql2');
const fs = require('fs');
const path = require('path');

// Configuração do banco de dados
const dbConfig = {
    host: 'localhost',
    user: 'root',
    password: 'root',
    multipleStatements: true // Permite múltiplos comandos SQL
};

// Criar pool de conexões
const pool = mysql.createPool(dbConfig);
const promisePool = pool.promise();

// Função para inicializar o banco de dados
async function initializeDatabase() {
    try {
        // Ler o arquivo SQL
        const sqlPath = path.join(__dirname, '../database/init.sql');
        const initSQL = fs.readFileSync(sqlPath, 'utf8');

        // Executar os comandos SQL
        await promisePool.query(initSQL);
        console.log('Database initialized successfully');

    } catch (err) {
        console.error('Error initializing database:', err);
        throw err;
    }
}

// Inicializar o banco de dados
initializeDatabase().catch(err => {
    console.error('Failed to initialize database:', err);
    process.exit(1);
});

// Funções auxiliares para operações no banco
const db = {
    // Dispositivos
    async createDevice(deviceData) {
        const [result] = await promisePool.execute(
            'INSERT INTO devices (device_id, name, description, location) VALUES (?, ?, ?, ?)',
            [deviceData.device_id, deviceData.name, deviceData.description, deviceData.location]
        );
        return result.insertId;
    },

    async getDevice(deviceId) {
        const [rows] = await promisePool.execute(
            'SELECT * FROM devices WHERE device_id = ?',
            [deviceId]
        );
        return rows[0];
    },

    async updateDevice(deviceId, deviceData) {
        const [result] = await promisePool.execute(
            'UPDATE devices SET name = ?, description = ?, location = ?, active = ?, last_seen = NOW() WHERE device_id = ?',
            [deviceData.name, deviceData.description, deviceData.location, deviceData.active, deviceId]
        );
        return result.affectedRows > 0;
    },

    async deleteDevice(deviceId) {
        const [result] = await promisePool.execute(
            'DELETE FROM devices WHERE device_id = ?',
            [deviceId]
        );
        return result.affectedRows > 0;
    },

    // Dados dos sensores
    async addSensorData(sensorData) {
        const [result] = await promisePool.execute(
            'INSERT INTO sensor_data (device_id, sensor_type, value, unit, location, battery_level, signal_strength) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
                sensorData.device_id,
                sensorData.sensor_type,
                sensorData.value,
                sensorData.unit,
                sensorData.location,
                sensorData.battery_level,
                sensorData.signal_strength
            ]
        );
        return result.insertId;
    },

    async getSensorData(deviceId, limit = 100) {
        const [rows] = await promisePool.execute(
            'SELECT * FROM sensor_data WHERE device_id = ? ORDER BY created_at DESC LIMIT ?',
            [deviceId, limit]
        );
        return rows;
    },

    async getLatestReadings() {
        const [rows] = await promisePool.execute('SELECT * FROM latest_readings');
        return rows;
    },

    // Configurações
    async getSetting(key) {
        const [rows] = await promisePool.execute(
            'SELECT * FROM settings WHERE setting_key = ?',
            [key]
        );
        return rows[0];
    },

    async updateSetting(key, value, description) {
        const [result] = await promisePool.execute(
            'INSERT INTO settings (setting_key, setting_value, description) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE setting_value = ?, description = ?',
            [key, JSON.stringify(value), description, JSON.stringify(value), description]
        );
        return result.affectedRows > 0;
    },

    // Função genérica para consultas personalizadas
    async query(sql, params = []) {
        const [rows] = await promisePool.execute(sql, params);
        return rows;
    }
};

module.exports = db; 