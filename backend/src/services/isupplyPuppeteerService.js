const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
puppeteer.use(StealthPlugin());

let sharedBrowser = null;
let sharedPage = null;

const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

async function getBrowserInstance() {
    if (sharedBrowser && sharedBrowser.isConnected()) {
        return sharedBrowser;
    }
    sharedBrowser = await puppeteer.launch({
        headless: false, // Set to false so the user can see the browser
        slowMo: 50,      // Slow down operations by 50ms to make it more visible
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-blink-features=AutomationControlled',
            '--window-size=1280,1000'
        ]
    });
    return sharedBrowser;
}

async function ensureAuthenticated() {
    const browser = await getBrowserInstance();
    
    if (sharedPage && !sharedPage.isClosed()) {
        try {
            const currentUrl = sharedPage.url();
            if (currentUrl.includes('isupply.com.eg') && !currentUrl.includes('/login')) {
                return sharedPage;
            }
        } catch (e) {
            console.log('[iSupply Puppeteer] Page context lost, creating new one...');
            sharedPage = null;
        }
    }

    if (!sharedPage || sharedPage.isClosed()) {
        sharedPage = await browser.newPage();
        await sharedPage.setUserAgent(USER_AGENT);
        await sharedPage.setViewport({ width: 1280, height: 1000 });
    }
    
    // Only navigate to search page if we don't have a valid isupply URL
    if (!sharedPage.url().includes('isupply.com.eg')) {
        console.log('[iSupply Puppeteer] Navigating to iSupply (initial load)...');
        await sharedPage.goto('https://app.isupply.com.eg/best-price/products/search', { waitUntil: 'networkidle2' });
    }

    // If redirected to login, perform login
    if (sharedPage.url().includes('/login')) {
        console.log('[iSupply Puppeteer] Redirected to login. Performing automated login...');
        
        const idSelector = 'input[wire\\:model="form.identifier"]';
        const passSelector = 'input[wire\\:model="form.password"]';
        
        await sharedPage.waitForSelector(idSelector, { timeout: 15000 });
        
        // Robust typing for Livewire
        async function robustType(selector, text) {
            await sharedPage.waitForSelector(selector);
            await sharedPage.focus(selector);
            
            await sharedPage.evaluate((sel) => {
                const el = document.querySelector(sel);
                if (el) el.value = '';
            }, selector);

            await sharedPage.type(selector, text, { delay: 100 });
            await sharedPage.keyboard.press('Tab');
            await new Promise(r => setTimeout(r, 800));
        }

        await robustType(idSelector, process.env.ISUPPLY_USERNAME);
        await robustType(passSelector, process.env.ISUPPLY_PASSWORD);

        console.log('[iSupply Puppeteer] Submitting login form...');
        await sharedPage.evaluate(() => {
            const btn = document.querySelector('button[type="submit"]');
            if (btn) btn.click();
        });

        // Wait for redirect or check URL periodically
        console.log('[iSupply Puppeteer] Waiting for login to settle...');
        let authenticated = false;
        for (let i = 0; i < 15; i++) {
            await new Promise(r => setTimeout(r, 2000));
            try {
                if (!sharedPage.url().includes('/login')) {
                    authenticated = true;
                    break;
                }
            } catch (e) { break; }
        }

        if (!authenticated) {
            console.log('[iSupply Puppeteer] Still on login. Trying one more Enter...');
            try {
                await sharedPage.focus(passSelector);
                await sharedPage.keyboard.press('Enter');
                await new Promise(r => setTimeout(r, 8000));
            } catch (e) {}
        }

        // Final check: are we off the login page?
        if (sharedPage.url().includes('/login')) {
            await sharedPage.screenshot({ path: 'login_failure_retry.png' });
            throw new Error(`Login failed: Still on ${sharedPage.url()}`);
        }

        // Ensure we end up on search page
        if (!sharedPage.url().includes('/products/search')) {
            console.log('[iSupply Puppeteer] Navigating to search page after login...');
            await sharedPage.goto('https://app.isupply.com.eg/best-price/products/search', { waitUntil: 'networkidle2' });
        }
    }

    return sharedPage;
}

/**
 * Direct search pattern using URL query params
 * returns [ { id, title, price }, ... ]
 */
async function searchIProductsDirect(keyword) {
    const page = await ensureAuthenticated();
    const url = `https://app.isupply.com.eg/products/search?keyword=${encodeURIComponent(keyword)}&category=1`;
    
    console.log(`[iSupply Puppeteer] Direct search: ${url}`);
    await page.goto(url, { waitUntil: 'networkidle2' });

    // Based on user feedback, the results appear as a JSON-like array on the page
    const products = await page.evaluate(() => {
        try {
            const bodyText = document.body.innerText.trim();
            // Try to find a JSON array in the text
            const match = bodyText.match(/\[\s*\{.*\}\s*\]/s);
            if (match) {
                return JSON.parse(match[0]);
            }
            // Fallback: search for list items if it's rendered HTML
            const items = Array.from(document.querySelectorAll('li, div.product-item')).map(el => {
                const text = el.innerText;
                const idMatch = text.match(/ID:\s*(\d+)/i);
                const priceMatch = text.match(/(\d+\.?\d*)\s*(EGP|ج\.م)/i);
                if (priceMatch) {
                    return {
                        id: idMatch ? parseInt(idMatch[1]) : Math.random(),
                        title: text.split('\n')[0].trim(),
                        price: parseFloat(priceMatch[1])
                    };
                }
                return null;
            }).filter(i => i !== null);

            return items;
        } catch (e) {
            return [];
        }
    });

    return products;
}

async function fetchProductSalesUI(isupplyTitle) {
    const page = await ensureAuthenticated();
    
    console.log(`[iSupply Puppeteer] Fetching sales for: ${isupplyTitle}`);
    
    // 1. Navigate to products page (Always fresh start)
    await page.goto('https://app.isupply.com.eg/best-price/products/search', { waitUntil: 'networkidle2' });

    // 2. Interact with the Select2 search
    try {
        // Find the placeholder span and click it
        const placeholderSelector = '.select2-selection__placeholder';
        await page.waitForSelector(placeholderSelector, { timeout: 15000 });
        await page.click(placeholderSelector);
        
        // After clicking, the input should be focused. We wait a moment for it to appear.
        await new Promise(r => setTimeout(r, 1000));
        
        // Type the title. Since it's focused by default after click, we just type.
        await page.keyboard.type(isupplyTitle, { delay: 100 });
        await page.keyboard.press('Enter');
        
        // Wait for selection to settle
        await new Promise(r => setTimeout(r, 2000));

        // 3. Click the "Search" button (class "i-search-best-btn btn bold")
        const searchBtn = '.i-search-best-btn';
        await page.waitForSelector(searchBtn, { timeout: 10000 });
        await page.click(searchBtn);

        // 4. Wait for results to load
        console.log('[iSupply Puppeteer] Waiting for search results...');
        await new Promise(r => setTimeout(r, 5000)); // Allow Livewire to render

        // 5. Extract sales data
        const sales = await page.evaluate(() => {
            const results = [];
            const cards = document.querySelectorAll('.i-product-card');
            
            cards.forEach(card => {
                // Discount is usually the boldest blue text
                const discountEl = card.querySelector('.i-text-blue.fw-bolder');
                const discountText = discountEl ? discountEl.innerText.trim() : '0%';
                
                // Seller is an anchor tag with specific classes
                const sellerEl = card.querySelector('a.h4.fw-bold.i-text-blue');
                const sellerName = sellerEl ? sellerEl.innerText.trim() : 'Unknown';
                
                // Prices are inside spans with fw-bold. Consumer price usually doesn't have custom color style.
                // We'll search for the one that contains "جم" or "EGP"
                const priceSpans = Array.from(card.querySelectorAll('span.fw-bold'));
                let consumerPrice = 0;
                let pharmacyPrice = 0;

                priceSpans.forEach(span => {
                    const text = span.innerText;
                    if (text.includes('سعر المستهلك')) {
                        consumerPrice = parseFloat(text.replace(/[^\d.]/g, '')) || 0;
                    } else if (text.includes('سعر الصيدلية')) {
                        pharmacyPrice = parseFloat(text.replace(/[^\d.]/g, '')) || 0;
                    }
                });
                
                const discount = parseInt(discountText.replace('%', '')) || 0;
                
                results.push({
                    discount,
                    consumerPrice,
                    pharmacyPrice,
                    seller: sellerName
                });
            });
            return results;
        });

        console.log(`[iSupply Puppeteer] Found ${sales.length} sales entries.`);
        return sales;

    } catch (err) {
        console.error(`[iSupply Puppeteer] Error fetching sales for ${isupplyTitle}:`, err.message);
        return [];
    }
}

module.exports = {
    searchIProductsDirect,
    fetchProductSalesUI,
    ensureAuthenticated
};
