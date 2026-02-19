const jwt = require('jsonwebtoken');
const { User, Pharmacy } = require('../models');
const auditService = require('./auditService');

/**
 * Generates a JWT token for a user.
 * @param {string} id User ID
 * @returns {string} JWT Token
 */
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

/**
 * Registers a new user and potentially links them to a pharmacy.
 */
exports.registerUser = async (userData, req = null) => {
    const { name, phone, email, password, role, pharmacyId } = userData;

    // Check if user exists
    const userExists = await User.findOne({ 
        $or: [{ email }, { phone }] 
    });

    if (userExists) {
        throw new Error('User already exists with this email or phone');
    }

    const userRole = role || 'pharmacy_owner';

    const user = await User.create({
        name,
        phone: phone || `temp_${Date.now()}`,
        email,
        hashedPassword: password || `social_${Math.random()}`,
        role: userRole,
        pharmacy: pharmacyId || undefined,
        status: 'pending'
    });

    if (user) {
        await auditService.logAction({
            user: user._id,
            action: 'CREATE',
            entityType: 'User',
            entityId: user._id,
            changes: { email: user.email, role: user.role }
        }, req);

        return {
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            status: user.status,
            token: generateToken(user._id)
        };
    } else {
        throw new Error('Invalid user data');
    }
};

/**
 * Authenticates a user and updates their last login.
 */
exports.loginUser = async (email, password, req = null) => {
    const user = await User.findOne({ email }).populate('pharmacy');

    if (user && (await user.comparePassword(password))) {
        user.lastLogin = Date.now();
        await user.save();

        await auditService.logAction({
            user: user._id,
            action: 'LOGIN',
            entityType: 'User',
            entityId: user._id
        }, req);

        return {
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            status: user.status,
            pharmacy: user.pharmacy,
            token: generateToken(user._id)
        };
    } else {
        throw new Error('Invalid email or password');
    }
};

/**
 * Google/Social Login
 */
exports.socialLogin = async (userData, req = null) => {
    const { email, name } = userData;
    let user = await User.findOne({ email }).populate('pharmacy');

    if (!user) {
        user = await User.create({
            email,
            name,
            phone: `social_${Date.now()}`,
            hashedPassword: `social_${Math.random()}`,
            role: 'pharmacy_owner',
            status: 'pending'
        });
    }

    await auditService.logAction({
        user: user._id,
        action: 'LOGIN_SOCIAL',
        entityType: 'User',
        entityId: user._id
    }, req);

    return {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
        pharmacy: user.pharmacy,
        token: generateToken(user._id)
    };
};

/**
 * Links pharmacy to a user.
 */
exports.linkPharmacy = async (userId, pharmacyData, session, req = null) => {
    const user = await User.findById(userId).session(session);
    if (!user) throw new Error('User not found');

    const pharmacy = new Pharmacy({
        ...pharmacyData,
        status: 'pending'
    });
    await pharmacy.save({ session });

    user.pharmacy = pharmacy._id;
    user.status = 'waiting';
    await user.save({ session });

    await auditService.logAction({
        user: userId,
        action: 'LINK_PHARMACY',
        entityType: 'Pharmacy',
        entityId: pharmacy._id
    }, req);

    await user.populate('pharmacy');
    return { user, pharmacy };
};

/**
 * Changes user password.
 */
exports.changePassword = async (userId, oldPassword, newPassword, req = null) => {
    const user = await User.findById(userId);
    if (!user) throw new Error('User not found');

    const isMatch = await user.comparePassword(oldPassword);
    if (!isMatch) throw new Error('Incorrect old password');

    user.hashedPassword = newPassword;
    await user.save();

    await auditService.logAction({
        user: userId,
        action: 'CHANGE_PASSWORD',
        entityType: 'User',
        entityId: userId
    }, req);

    return true;
};

/**
 * Updates a user's profile or pending data.
 */
exports.updateUserDetail = async (userId, updateData, req = null) => {
    const user = await User.findById(userId);
    if (!user) throw new Error('User not found');

    if (updateData.email && updateData.email.toLowerCase() !== user.email) {
        const emailExists = await User.findOne({ email: updateData.email.toLowerCase() });
        if (emailExists) throw new Error('Email already in use');
    }

    user.pendingUpdate = updateData;
    await user.save();

    await auditService.logAction({
        user: userId,
        action: 'UPDATE_REQUEST',
        entityType: 'User',
        entityId: userId,
        changes: updateData
    }, req);

    await user.populate('pharmacy');
    return user;
};
