const jwt = require('jsonwebtoken');
const { User, Pharmacy } = require('../models');
const { deleteFiles } = require('../utils/fileHelper');

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

        // If role is admin, pharmacy is not required. 
        // For others, it's initially not required (status: pending)
        // But role must be assigned.
        const userRole = role || 'pharmacy_owner';

        // Create user
        const user = await User.create({
            name,
            phone: phone || `temp_${Date.now()}`, // Fallback for social login if not provided initially
            email,
            hashedPassword: password || `social_${Math.random()}`, // Random pass for social login placeholders
            role: userRole,
            pharmacy: pharmacyId || undefined,
            status: 'pending'
        });

        if (user) {
            res.status(201).json({
                success: true,
                data: {
                    _id: user._id,
                    name: user.name,
                    email: user.email,
                    role: user.role,
                    status: user.status,
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
                    status: user.status,
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

// @desc    Link pharmacy to a pending user
// @route   POST /api/auth/link-pharmacy
// @access  Private (Pending/Waiting)
const linkPharmacy = async (req, res) => {
    try {
        console.log("recived")
        const { 
            name, ownerName, nationalId, phone, email,
            location 
        } = req.body;

        // Parse location if it is a string
        let parsedLocation = location;
        if (typeof parsedLocation === 'string') {
            try { parsedLocation = JSON.parse(parsedLocation); } catch (e) {}
        }

        // Helper to cleanup files if any error occurs
        const cleanup = () => {
            if (req.files) {
                const files = Object.values(req.files).flat().map(f => f.path);
                if (files.length > 0) deleteFiles(files);
            }
        };

        const user = await User.findById(req.user._id);

        if (!user) {
            cleanup();
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        if (nationalId && !/^\d{14}$/.test(nationalId)) {
            cleanup();
            return res.status(400).json({ success: false, message: 'National ID must be exactly 14 digits' });
        }

        if (user.status === 'active') {
            cleanup();
            return res.status(400).json({ success: false, message: 'Account already active' });
        }

        // Extract file paths
        const pharmacistCard = req.files['pharmacistCard'] ? req.files['pharmacistCard'][0].path : null;
        const commercialRegistry = req.files['commercialRegistry'] ? req.files['commercialRegistry'][0].path : null;
        const taxCard = req.files['taxCard'] ? req.files['taxCard'][0].path : null;
        const pharmacyLicense = req.files['pharmacyLicense'] ? req.files['pharmacyLicense'][0].path : null;

        if (!pharmacistCard || !commercialRegistry || !taxCard || !pharmacyLicense) {
            cleanup();
            return res.status(400).json({ success: false, message: 'All 4 documents are required' });
        }

        // Create new pharmacy record
        const pharmacy = await Pharmacy.create({
            name,
            ownerName,
            nationalId,
            phone: phone || user.phone,
            email: email || user.email,
            pharmacistCard,
            commercialRegistry,
            taxCard,
            pharmacyLicense,
            address,
            location: parsedLocation,
            status: 'pending'
        });

        // Update user
        user.pharmacy = pharmacy._id;
        user.status = 'waiting';
        await user.save();

        res.status(200).json({ 
            success: true, 
            message: 'Pharmacy linked. Awaiting admin approval.',
            data: { user, pharmacy }
        });
    } catch (error) {
        console.log(error);
        // Cleanup if error occurs during DB operations
        const files = req.files ? Object.values(req.files).flat().map(f => f.path) : [];
        if (files.length > 0) deleteFiles(files);
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Google/Social Login Placeholder
// @route   POST /api/auth/social-login
// @access  Public
const socialLogin = async (req, res) => {
    try {
        const { email, name, provider, providerId } = req.body;

        let user = await User.findOne({ email });

        if (!user) {
            // Create user if not exists
            user = await User.create({
                email,
                name,
                phone: `social_${Date.now()}`, // User needs to update this later
                hashedPassword: `social_${Math.random()}`,
                role: 'pharmacy_owner',
                status: 'pending'
            });
        }

        res.json({
            success: true,
            data: {
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                status: user.status,
                pharmacy: user.pharmacy,
                token: generateToken(user._id)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

module.exports = {
    register,
    login,
    getProfile,
    linkPharmacy,
    socialLogin
};
