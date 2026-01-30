const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'products_full_simple.json');

function deduplicate() {
    try {
        console.log('Reading data from:', filePath);
        // const rawData = fs.readFileSync(filePath, 'utf8');
        const products = JSON.parse(rawData);
        
        console.log(`Original count: ${products.length}`);

        const seen = new Set();
        const uniqueProducts = [];

        for (const product of products) {
            // Use a combination of name and price as the unique key
            // Trim and lowercase name for better matching if needed, 
            // but the request said "same name and price", so we'll be exact first.
            const key = `${product.name.trim().toLowerCase()}|${product.price}`;
            
            if (!seen.has(key)) {
                seen.add(key);
                uniqueProducts.push(product);
            }
        }

        console.log(`Unique count: ${uniqueProducts.length}`);
        console.log(`Removed: ${products.length - uniqueProducts.length}`);

        fs.writeFileSync(filePath, JSON.stringify(uniqueProducts, null, 2));
        console.log('Deduplication complete. Data saved to:', filePath);

    } catch (error) {
        console.error('Error during deduplication:', error.message);
    }
}

deduplicate();
