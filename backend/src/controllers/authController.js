const jwt = require('jsonwebtoken');
const { User, Pharmacy } = require('../models');
const { deleteFiles } = require('../utils/fileHelper');
const cloudinary = require('cloudinary').v2;
const fs = require('fs');

// Configure Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});
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
        const user = await User.findOne({ email }).populate('pharmacy');

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
        console.log("received")
        const { 
            name, ownerName, nationalId, phone, email,
            address, location 
        } = req.body;

        // Parse location if it is a string
        let parsedLocation = location;
        if (typeof parsedLocation === 'string') {
            try { parsedLocation = JSON.parse(parsedLocation); } catch (e) {}
        }

        // Helper to cleanup files (local Multer files)
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

        // Extract file paths from Multer (Required)
        // Check if files exist
        if (!req.files || !req.files['pharmacistCard'] || !req.files['commercialRegistry'] || !req.files['taxCard'] || !req.files['pharmacyLicense']) {
            cleanup();
            return res.status(400).json({ success: false, message: 'All 4 documents are required' });
        }

        // --- All Validation Passed ---
        const useCloudinary = process.env.USE_CLOUDINARY === 'true';
        const fileKeys = ['pharmacistCard', 'commercialRegistry', 'taxCard', 'pharmacyLicense'];
        const uploadResults = {};

        if (useCloudinary) {
            console.log("☁️ [Cloudinary] Uploading files...");
            const uploadToCloudinary = async (filePath) => {
                return await cloudinary.uploader.upload(filePath, {
                    folder: 'pharmacy_docs',
                    resource_type: 'image'
                });
            };

            try {
                for (const key of fileKeys) {
                    const file = req.files[key][0];
                    const result = await uploadToCloudinary(file.path);
                    uploadResults[key] = result.secure_url;
                    
                    // Delete local file after upload
                    fs.unlinkSync(file.path);
                }
            } catch (uploadError) {
                cleanup(); // Try to delete remaining local files
                console.error('Cloudinary Upload Error:', uploadError);
                return res.status(500).json({ success: false, message: 'Image upload failed' });
            }
        } else {
            console.log("📂 [Local] Using local file paths...");
            for (const key of fileKeys) {
                uploadResults[key] = req.files[key][0].path;
            }
        }

        // Create new pharmacy record
        const pharmacy = await Pharmacy.create({
            name,
            ownerName,
            nationalId,
            phone: phone || user.phone,
            email: email || user.email,
            pharmacistCard: uploadResults.pharmacistCard,
            commercialRegistry: uploadResults.commercialRegistry,
            taxCard: uploadResults.taxCard,
            pharmacyLicense: uploadResults.pharmacyLicense,
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
        console.error('Registration/Store Update Error:', error);
        const cleanup = () => {
             if (req.files) {
                 const files = Object.values(req.files).flat().map(f => f.path);
                 if (files.length > 0) deleteFiles(files);
             }
        };
        cleanup();
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

// @desc    Request a profile update (Name or Pharmacy Data)
// @route   PUT /api/auth/profile-update-request
// @access  Private
const requestProfileUpdate = async (req, res) => {
    try {
        const { name, email, phone, pharmacy } = req.body;
        const user = await User.findById(req.user._id);

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Check if requested email is already taken by ANOTHER user
        if (email && email.toLowerCase() !== user.email) {
            const emailExists = await User.findOne({ email: email.toLowerCase() });
            if (emailExists) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'The requested email is already in use by another account.' 
                });
            }
        }

        // Save requested changes to pendingUpdate
        user.pendingUpdate = {
            name,
            email,
            phone,
            pharmacy // Should contain updated pharmacy fields if provided
        };

        await user.save();
        await user.populate('pharmacy');

        res.status(200).json({ 
            success: true, 
            message: 'Update request sent to admin for approval.',
            data: user 
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// @desc    Change user password
// @route   PUT /api/auth/change-password
// @access  Private
const changePassword = async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const user = await User.findById(req.user._id);

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // Verify old password
        const isMatch = await user.comparePassword(oldPassword);
        if (!isMatch) {
            return res.status(400).json({ success: false, message: 'Incorrect old password' });
        }

        // Set new password
        user.hashedPassword = newPassword;
        await user.save();

        res.status(200).json({ success: true, message: 'Password changed successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

module.exports = {
    register,
    login,
    getProfile,
    linkPharmacy,
    socialLogin,
    requestProfileUpdate,
    changePassword
};
