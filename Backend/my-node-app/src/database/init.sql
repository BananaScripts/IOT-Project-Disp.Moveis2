-- Criar o banco de dados se não existir
CREATE DATABASE IF NOT EXISTS iot_database;

-- Usar o banco de dados
USE iot_database;

-- Criar tabela para os dados dos sensores
CREATE TABLE IF NOT EXISTS sensor_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    sensor_type VARCHAR(50) NOT NULL,
    value FLOAT NOT NULL,
    unit VARCHAR(20),
    location VARCHAR(100),
    battery_level INT,
    signal_strength INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_device_id (device_id),
    INDEX idx_sensor_type (sensor_type),
    INDEX idx_created_at (created_at)
);

-- Criar tabela para informações dos dispositivos
CREATE TABLE IF NOT EXISTS devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(100),
    active BOOLEAN DEFAULT true,
    last_seen TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_active (active)
);

-- Criar tabela para configurações
CREATE TABLE IF NOT EXISTS settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(50) NOT NULL UNIQUE,
    setting_value JSON NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Inserir algumas configurações padrão
INSERT IGNORE INTO settings (setting_key, setting_value, description) VALUES
('temperature_limits', '{"min": -40, "max": 85, "unit": "celsius"}', 'Limites de temperatura aceitáveis'),
('humidity_limits', '{"min": 0, "max": 100, "unit": "percent"}', 'Limites de umidade aceitáveis'),
('sampling_rate', '{"default": 60, "unit": "seconds"}', 'Taxa de amostragem padrão');

-- Criar view para últimas leituras por dispositivo
CREATE OR REPLACE VIEW latest_readings AS
SELECT 
    d.device_id,
    d.name as device_name,
    d.location,
    sd.sensor_type,
    sd.value,
    sd.unit,
    sd.created_at as reading_time,
    d.last_seen,
    d.active
FROM devices d
LEFT JOIN (
    SELECT 
        device_id,
        sensor_type,
        value,
        unit,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY device_id, sensor_type ORDER BY created_at DESC) as rn
    FROM sensor_data
) sd ON d.device_id = sd.device_id AND sd.rn = 1; 