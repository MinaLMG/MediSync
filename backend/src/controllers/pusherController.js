const { initPusher } = require('../utils/pusherManager');

// @desc    Authenticate Pusher private channel
// @route   POST /api/pusher/auth
// @access  Private
exports.authenticate = (req, res) => {
    const socketId = req.body.socket_id;
    const channel = req.body.channel_name;
    const userId = req.user._id.toString();

    // Verify that the user is trying to join THEIR OWN private channel
    // Private channel format: private-user-{userId}
    if (channel !== `private-user-${userId}`) {
        return res.status(403).json({ 
            success: false, 
            message: 'Forbidden: You can only subscribe to your own private channel' 
        });
    }

    const pusher = initPusher();
    // Presence data can be added here if needed
    const auth = pusher.authenticate(socketId, channel);
    res.send(auth);
};
