const fs = require('fs');
const path = require('path');

/**
 * Deletes files from the filesystem
 * @param {string|string[]} paths - Single path or array of paths to delete
 */
const deleteFiles = (paths) => {
    const pathArray = Array.isArray(paths) ? paths : [paths];
    console.log(pathArray);
    pathArray.forEach(filePath => {
        if (filePath) {
            // Document path might be relative to backend root 'uploads/file.png'
            // Ensure we have a valid absolute path or relative from current process
            const absolutePath = path.isAbsolute(filePath) 
                ? filePath 
                : path.join(process.cwd(), filePath);

            if (fs.existsSync(absolutePath)) {
                try {
                    fs.unlinkSync(absolutePath);
                    console.log(`Successfully deleted file: ${absolutePath}`);
                } catch (err) {
                    console.error(`Error deleting file ${absolutePath}:`, err);
                }
            } else {
                console.warn(`File not found for deletion: ${absolutePath}`);
            }
        }
    });
};

module.exports = {
    deleteFiles
};
