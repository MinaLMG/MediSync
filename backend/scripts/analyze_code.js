const fs = require('fs');
const path = require('path');

const controllersDir = path.join(__dirname, '..', 'src', 'controllers');
const servicesDir = path.join(__dirname, '..', 'src', 'services');

function analyzeFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.split('\n');
    const exportsList = [];
    
    // Find comments and function names
    let tempComment = [];
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        
        if (line.startsWith('//') || line.startsWith('/*') || line.startsWith('*')) {
            tempComment.push(line);
        } else {
            // Check for exports.functionName = async (req, res) or similar
            // OR exports.functionName = async (...) or function functionName(...)
            const exportMatch = line.match(/(exports\.\w+|const\s+\w+\s*=\s*(?:async\s*)?\([^)]*\)\s*=>|async\s*function\s+(\w+))/);
            const genericMatch = line.match(/(?:exports\.)?(\w+)\s*=\s*(?:async\s*)?\(([^)]*)\)/) || line.match(/function\s+(\w+)\s*\(([^)]*)\)/);
            
            if (genericMatch) {
                const name = genericMatch[1];
                const params = genericMatch[2];
                if (name && name !== 'if' && name !== 'for' && name !== 'while' && name !== 'switch') {
                    // Extract function body to see what models/services it refers to
                    let body = '';
                    let braceCount = 0;
                    let started = false;
                    for (let j = i; j < lines.length; j++) {
                        const l = lines[j];
                        if (l.includes('{')) {
                            braceCount += (l.match(/{/g) || []).length;
                            started = true;
                        }
                        if (l.includes('}')) {
                            braceCount -= (l.match(/}/g) || []).length;
                        }
                        body += l + '\n';
                        if (started && braceCount <= 0) {
                            break;
                        }
                    }
                    
                    // Simple regex checks on function body
                    const modelsMatch = body.match(/[A-Z][a-zA-Z0-9]+(?=\.(find|findOne|findById|create|save|update|delete|aggregate|distinct))/g) || [];
                    const servicesMatch = body.match(/\w+Service\.\w+/g) || [];
                    const uniqueModels = [...new Set(modelsMatch)];
                    const uniqueServices = [...new Set(servicesMatch)];
                    
                    exportsList.push({
                        name,
                        params: params.split(',').map(p => p.trim()).filter(Boolean),
                        comment: tempComment.join('\n'),
                        modelsUsed: uniqueModels,
                        servicesUsed: uniqueServices,
                        startLine: i + 1
                    });
                }
                tempComment = [];
            } else if (line !== '') {
                tempComment = [];
            }
        }
    }
    return exportsList;
}

const controllersAnalysis = {};
fs.readdirSync(controllersDir).forEach(file => {
    if (file.endsWith('.js') && file !== '.gitkeep') {
        controllersAnalysis[file] = analyzeFile(path.join(controllersDir, file));
    }
});

const servicesAnalysis = {};
fs.readdirSync(servicesDir).forEach(file => {
    if (file.endsWith('.js')) {
        servicesAnalysis[file] = analyzeFile(path.join(servicesDir, file));
    }
});

fs.writeFileSync(path.join(__dirname, '..', 'code_analysis.json'), JSON.stringify({ controllers: controllersAnalysis, services: servicesAnalysis }, null, 2));
console.log("Analysis file generated successfully at code_analysis.json");
