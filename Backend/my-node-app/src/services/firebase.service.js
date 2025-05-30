const { db, setupFirestore } = require('../config/firebase');
const { 
    collection, 
    doc, 
    addDoc, 
    getDoc, 
    getDocs, 
    updateDoc, 
    deleteDoc, 
    query, 
    where,
    orderBy,
    limit,
    serverTimestamp,
    setDoc,
    enableNetwork
} = require('firebase/firestore');

class FirebaseService {
    constructor() {
        this.initialized = false;
        this.initPromise = this.initializeService();
        this.operationTimeout = 25000; // 25 segundos
    }

    async initializeService() {
        if (this.initialized) return;

        try {
            console.log('Initializing Firebase Service...');
            const result = await setupFirestore();
            
            if (!result.success) {
                throw new Error(`Falha na inicialização do Firestore: ${result.error}`);
            }

            // Tenta habilitar a rede explicitamente
            await enableNetwork(db);

            this.initialized = true;
            console.log('✓ Firebase Service initialized successfully');
            return true;
        } catch (error) {
            console.error('✗ Failed to initialize Firebase Service:', error);
            this.initialized = false;
            throw error;
        }
    }

    async ensureOperation(operation) {
        const maxRetries = 3;
        let attempt = 0;

        while (attempt < maxRetries) {
            try {
                if (!this.initialized) {
                    console.log(`Initialization attempt ${attempt + 1}/${maxRetries}...`);
                    await this.initPromise;
                }

                // Adiciona um timeout para a operação
                const timeoutPromise = new Promise((_, reject) => {
                    setTimeout(() => {
                        reject(new Error('Operation timeout'));
                    }, this.operationTimeout);
                });

                // Executa a operação com timeout
                return await Promise.race([
                    operation(),
                    timeoutPromise
                ]);
            } catch (error) {
                attempt++;
                console.error(`Operation failed (attempt ${attempt}/${maxRetries}):`, error);
                
                if (error.message === 'Operation timeout') {
                    throw new Error('A operação demorou muito para responder. Por favor, tente novamente.');
                }
                
                if (attempt === maxRetries) {
                    throw error;
                }
                
                // Espera exponencial entre tentativas
                await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
            }
        }
    }

    async ensureCollectionsExist() {
        return this.ensureOperation(async () => {
            try {
                // Tenta acessar as coleções
                const collections = ['devices', 'sensor_data'];
                
                for (const collectionName of collections) {
                    const testQuery = query(collection(db, collectionName), limit(1));
                    await getDocs(testQuery);
                }
                
                console.log('Collections verified successfully');
            } catch (error) {
                console.error('Error ensuring collections exist:', error);
                throw error;
            }
        });
    }

    // Dispositivos
    async createDevice(deviceData) {
        try {
            const devicesRef = collection(db, 'devices');
            const deviceDoc = await addDoc(devicesRef, {
                ...deviceData,
                active: true,
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp()
            });
            return deviceDoc.id;
        } catch (error) {
            console.error('Error creating device:', error);
            throw new Error(`Falha ao criar dispositivo: ${error.message}`);
        }
    }

    async getDevice(deviceId) {
        try {
            const deviceDoc = await getDoc(doc(db, 'devices', deviceId));
            if (!deviceDoc.exists()) return null;
            return { id: deviceDoc.id, ...deviceDoc.data() };
        } catch (error) {
            console.error('Error getting device:', error);
            throw error;
        }
    }

    async updateDevice(deviceId, deviceData) {
        try {
            const deviceRef = doc(db, 'devices', deviceId);
            await updateDoc(deviceRef, {
                ...deviceData,
                updatedAt: serverTimestamp()
            });
            return true;
        } catch (error) {
            console.error('Error updating device:', error);
            throw error;
        }
    }

    async deleteDevice(deviceId) {
        try {
            await deleteDoc(doc(db, 'devices', deviceId));
            return true;
        } catch (error) {
            console.error('Error deleting device:', error);
            throw error;
        }
    }

    // Dados dos sensores
    async addSensorData(sensorData) {
        return this.ensureOperation(async () => {
            console.log('Starting addSensorData operation...');
            
            try {
                // Validação básica dos dados
                if (!sensorData.deviceId) {
                    throw new Error('deviceId é obrigatório');
                }

                console.log('Formatting sensor data...');
                
                // Formatação dos dados
                const formattedData = {
                    device_id: sensorData.deviceId,
                    temperature: Number(sensorData.temperature) || 0,
                    humidity: Number(sensorData.humidity) || 0,
                    created_at: serverTimestamp()
                };

                // Adiciona campos opcionais se existirem
                if (sensorData.airQuality) formattedData.airQuality = Number(sensorData.airQuality);
                if (sensorData.batteryLevel) formattedData.batteryLevel = Number(sensorData.batteryLevel);
                if (sensorData.timestamp) {
                    try {
                        formattedData.timestamp = new Date(sensorData.timestamp);
                    } catch (e) {
                        console.warn('Invalid timestamp format, using server timestamp');
                        formattedData.timestamp = serverTimestamp();
                    }
                } else {
                    formattedData.timestamp = serverTimestamp();
                }

                console.log('Attempting to save data to Firestore...');
                
                const sensorDataRef = collection(db, 'sensor_data');
                const dataDoc = await addDoc(sensorDataRef, formattedData);
                
                console.log('✓ Data saved successfully with ID:', dataDoc.id);
                
                return {
                    id: dataDoc.id,
                    ...formattedData
                };
            } catch (error) {
                console.error('✗ Error in addSensorData:', error);
                
                if (error.code === 'not-found') {
                    throw new Error('Não foi possível acessar o banco de dados. Verifique se o projeto está corretamente configurado no Firebase Console.');
                }
                
                throw new Error(`Falha ao adicionar dados do sensor: ${error.message}`);
            }
        });
    }

    async getSensorData(deviceId, limitCount = 100) {
        try {
            const q = query(
                collection(db, 'sensor_data'),
                where('device_id', '==', deviceId),
                orderBy('timestamp', 'desc'),
                limit(limitCount)
            );
            
            const querySnapshot = await getDocs(q);
            return querySnapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
        } catch (error) {
            console.error('Error getting sensor data:', error);
            throw error;
        }
    }

    async getLatestReadings() {
        try {
            const devices = await this.getAllDevices();
            const latestData = [];

            for (const device of devices) {
                const q = query(
                    collection(db, 'sensor_data'),
                    where('device_id', '==', device.id),
                    orderBy('timestamp', 'desc'),
                    limit(1)
                );
                
                const querySnapshot = await getDocs(q);
                if (!querySnapshot.empty) {
                    latestData.push({
                        device: device,
                        lastReading: {
                            id: querySnapshot.docs[0].id,
                            ...querySnapshot.docs[0].data()
                        }
                    });
                }
            }

            return latestData;
        } catch (error) {
            console.error('Error getting latest readings:', error);
            throw error;
        }
    }

    // Métodos auxiliares
    async getAllDevices() {
        try {
            const querySnapshot = await getDocs(collection(db, 'devices'));
            return querySnapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
        } catch (error) {
            console.error('Error getting all devices:', error);
            throw error;
        }
    }
}

// Exporta uma única instância do serviço
module.exports = new FirebaseService(); 