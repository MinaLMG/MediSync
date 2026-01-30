const fs = require('fs');
const path = require('path');
const https = require('https');

// const API_BASE_URL = 'https://api.c0umyt3cda-pharmaove1-p1-public.model-t.cc.commerce.ondemand.com/occ/v2/pharma/products/search?fields=products(code%2Cname%2Csummary%2Cconfigurable%2CconfiguratorType%2Cmultidimensional%2Cprice(FULL)%2Cimages(DEFAULT)%2Cstock(FULL)%2CaverageRating%2CvariantOptions%2CbaseProduct%2CpriceRange(maxPrice(formattedValue)%2CminPrice(formattedValue)))%2Cfacets%2Cbreadcrumbs%2Cpagination(DEFAULT)%2Csorts(DEFAULT)%2CfreeTextSearch%2CcurrentQuery%2CkeywordRedirectUrl&query=%3Arelevance%3AallCategories%3ADRUG&pageSize=12&lang=en&curr=EGP';

const OUTPUT_PATH = path.join(__dirname, '../db/products_full_simple.json');
const TOTAL_PAGES = 647;

const fetchData = (url) => {
    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(new Error('Failed to parse JSON'));
                }
            });
        }).on('error', (err) => {
            reject(err);
        });
    });
};

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const run = async () => {
    const allSimplifiedProducts = [];
    
    console.log(`🚀 Starting product fetch for ${TOTAL_PAGES} pages...`);

    for (let page = 1; page <= TOTAL_PAGES; page++) {
        const url = `${API_BASE_URL}&currentPage=${page}`;
        console.log(`📦 Fetching page ${page}/${TOTAL_PAGES}...`);

        try {
            const data = await fetchData(url);
            
            if (data.products && Array.isArray(data.products)) {
                const simplified = data.products.map(p => ({
                    name: p.name,
                    price: p.publicPrice ? p.publicPrice.value : (p.price ? p.price.value : 0)
                }));
                allSimplifiedProducts.push(...simplified);
                console.log(`✅ Page ${page} processed. Total items so far: ${allSimplifiedProducts.length}`);
            } else {
                console.warn(`⚠️ Page ${page} has no products or data is invalid.`);
            }

            // Small delay to prevent hitting rate limits too hard
            await delay(100);

        } catch (error) {
            console.error(`❌ Error fetching page ${page}:`, error.message);
            // Optional: implement retry logic or exit
        }
    }

    console.log(`💾 Saving ${allSimplifiedProducts.length} items to ${OUTPUT_PATH}...`);
    fs.writeFileSync(OUTPUT_PATH, JSON.stringify(allSimplifiedProducts, null, 2));
    console.log('🎉 Done!');
};

run();
