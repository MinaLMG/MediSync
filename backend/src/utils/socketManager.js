const { Server } = require('socket.io');

let io;
const userSocketMap = new Map(); // Maps userId -> [socketId1, socketId2, ...]

/**
 * Initialize Socket.io server
 * @param {Object} server - HTTP server instance
 */
const initSocket = (server) => {
    io = new Server(server, {
        cors: {
            origin: "*", // Adjust for production
            methods: ["GET", "POST"]
        }
    });

    io.on('connection', (socket) => {
        const userId = socket.handshake.query.userId;
        
        if (userId) {
            console.log(`User connected: ${userId} (Socket: ${socket.id})`);
            
            // Map userId to socketId
            if (!userSocketMap.has(userId)) {
                userSocketMap.set(userId, []);
            }
            userSocketMap.get(userId).push(socket.id);
            
            // Join a private room for this user
            socket.join(`user_${userId}`);
        }

        socket.on('disconnect', () => {
            if (userId && userSocketMap.has(userId)) {
                const updatedSockets = userSocketMap.get(userId).filter(id => id !== socket.id);
                if (updatedSockets.length === 0) {
                    userSocketMap.delete(userId);
                } else {
                    userSocketMap.set(userId, updatedSockets);
                }
                console.log(`User disconnected: ${userId}`);
            }
        });
    });

    return io;
};

/**
 * Send event to a specific user
 * @param {string} userId - User ID
 * @param {string} event - Event name
 * @param {Object} data - Event data
 */
const sendToUser = (userId, event, data) => {
    if (io) {
        console.log(`📡 [SocketManager] Sending '${event}' to user: ${userId}`);
        io.to(`user_${userId}`).emit(event, data);
    } else {
        console.warn(`⚠️ [SocketManager] Cannot send '${event}': io not initialized`);
    }
};

/**
 * Get the io instance
 */
const getIO = () => {
    if (!io) {
        throw { message: 'Socket.io not initialized!', code: 500 };
    }
    return io;
};

module.exports = {
    initSocket,
    sendToUser,
    getIO
};
