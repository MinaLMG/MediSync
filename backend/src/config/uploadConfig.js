const multer = require('multer');
const path = require('path');
const fs = require('fs');

const os = require('os');

// Determine upload directory
// Vercel/Serverless: Use /tmp (Note: Files are ephemeral!)
// Local: Use 'uploads/pharmacy_docs'
const isProduction = process.env.NODE_ENV === 'production' || process.env.VERCEL;
const uploadDir = isProduction 
    ? path.join(os.tmpdir(), 'pharmacy_docs') 
    : 'uploads/pharmacy_docs';

// Ensure directory exists
try {
    if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
    }
} catch (error) {
    console.error('Error creating upload directory:', error);
    // Fallback if permission denied (though tmpdir should work)
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const extension = path.extname(file.originalname).toLowerCase();
    
    console.log(`[Upload] Receiving file: ${file.originalname}, Mimetype: ${file.mimetype}`);

    if (file.mimetype.startsWith('image/') || allowedExtensions.includes(extension)) {
        cb(null, true);
    } else {
        cb(new Error(`Only images are allowed! Received: ${file.mimetype}`), false);
    }
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    }
});

module.exports = upload;
