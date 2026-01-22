const jwt = require('jsonwebtoken');
const { User, Pharmacy } = require('../models');

// Generate JWT Token
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
const register = async (req, res) => {
    try {
        const { name, phone, email, password, role, pharmacyId } = req.body;

        // Check if user exists
        const userExists = await User.findOne({ 
            $or: [{ email }, { phone }] 
        });

        if (userExists) {
            return res.status(400).json({ 
                success: false, 
                message: 'User already exists with this email or phone' 
            });
        }

        // If role is not admin, pharmacy is required
        if (role !== 'admin' && !pharmacyId) {
            return res.status(400).json({
                success: false,
                message: 'Pharmacy ID is required for non-admin users'
            });
        }

        // Create user
        const user = await User.create({
            name,
            phone,
            email,
            hashedPassword: password, // Will be hashed by pre-save hook
            role,
            pharmacy: pharmacyId
        });

        if (user) {
            res.status(201).json({
                success: true,
                data: {
                    _id: user._id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    token: generateToken(user._id)
                }
            });
        } else {
            res.status(400).json({ success: false, message: 'Invalid user data' });
        }
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Authenticate user & get token
// @route   POST /api/auth/login
// @access  Public
const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Check for user email
        const user = await User.findOne({ email }).populate('pharmacy', 'name status');

        if (user && (await user.comparePassword(password))) {
            // Update last login
            user.lastLogin = Date.now();
            await user.save();

            res.json({
                success: true,
                data: {
                    _id: user._id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    pharmacy: user.pharmacy,
                    token: generateToken(user._id)
                }
            });
        } else {
            res.status(401).json({ success: false, message: 'Invalid credentials' });
        }
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Get current user profile
// @route   GET /api/auth/profile
// @access  Private
const getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user._id).populate('pharmacy');
        
        if (user) {
            res.json({
                success: true,
                data: user
            });
        } else {
            res.status(404).json({ success: false, message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

module.exports = {
    register,
    login,
    getProfile
};
