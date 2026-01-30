const fs = require('fs');
const path = require('path');

const simplifyProducts = () => {
    try {
        // const inputPath = path.join(__dirname, '../db/products.json');
        const outputPath = path.join(__dirname, '../db/products_simple.json');

        console.log(`📖 Reading ${inputPath}...`);
        const fileContent = fs.readFileSync(inputPath, 'utf8');
        const jsonData = JSON.parse(fileContent);

        if (!jsonData.products || !Array.isArray(jsonData.products)) {
            console.error('❌ Invalid products.json structure: "products" key not found or not an array');
            return;
        }

        console.log(`🔧 Simplifying ${jsonData.products.length} products...`);
        const simplified = jsonData.products.map(p => ({
            name: p.name,
            price: p.publicPrice ? p.publicPrice.value : 0
        }));

        fs.writeFileSync(outputPath, JSON.stringify(simplified, null, 2));
        console.log(`✅ Simplified data saved to ${outputPath}`);
        console.log(`📊 Total items: ${simplified.length}`);

    } catch (error) {
        console.error('❌ Error during simplification:', error.message);
    }
};

simplifyProducts();
