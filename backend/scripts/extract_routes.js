const fs = require('fs');
const path = require('path');

const routesDir = path.join(__dirname, '..', 'src', 'routes');
const files = fs.readdirSync(routesDir);

const results = {};

files.forEach(file => {
    if (file.endsWith('.js')) {
        const filePath = path.join(routesDir, file);
        const content = fs.readFileSync(filePath, 'utf-8');
        
        const endpointLines = content.split('\n').filter(line => {
            return line.includes('router.') && (line.includes('.get(') || line.includes('.post(') || line.includes('.put(') || line.includes('.delete(') || line.includes('.patch(') || line.includes('.use('));
        });
        
        results[file] = endpointLines.map(line => line.trim());
    }
});

fs.writeFileSync(path.join(__dirname, '..', 'routes_inventory.json'), JSON.stringify(results, null, 2));
console.log("Success! routes_inventory.json generated.");
