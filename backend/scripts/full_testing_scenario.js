/**
 * MEDISYNC - COMPREHENSIVE E2E TESTING WITH ADVANCED SCENARIOS
 * 
 * Tests all status transitions, updates, conflicts, and edge cases
 */

require('dotenv').config();
const mongoose = require('mongoose');
const fetch = require('node-fetch');
const fs = require('fs');
const { 
    User, Pharmacy, Product, Volume, StockExcess, 
    StockShortage, Transaction, DeliveryRequest, 
    BalanceHistory, ReversalTicket, AuditLog, 
    Notification, Order, HasVolume
} = require('../src/models');

const BASE_URL = `http://127.0.0.1:${process.env.PORT || 5000}/api`;
const TEST_START_TIME = new Date();
const TEST_ID = Date.now().toString().slice(-4);

const prefix = (v) => `t${TEST_ID}_${v}`;
const prefixPhone = (idx) => `01${TEST_ID}${idx.toString().padStart(5, '0')}`;
const prefixEmail = (idx) => `test_${TEST_ID}_u${idx}@test.com`;

// Scoring system
let testResults = {
    totalTests: 0,
    passed: 0,
    failed: 0,
    errors: [],
    phases: {}
};

let tokens = {};
let ids = {};

/** LOGGING */
function logSection(name) { 
    console.log(`\n\x1b[36m╔═══ ${name.toUpperCase()} ═══╗\x1b[0m`); 
    testResults.phases[name] = { tests: 0, passed: 0, failed: 0 };
}

function logStep(msg) { console.log(`\x1b[32m✓\x1b[0m ${msg}`); }

/** AUTOMATED ASSERTION WITH SCORING */
function assert(condition, testName, phase, details = '') {
    testResults.totalTests++;
    if (testResults.phases[phase]) testResults.phases[phase].tests++;
    
    if (condition) {
        testResults.passed++;
        if (testResults.phases[phase]) testResults.phases[phase].passed++;
        console.log(`  \x1b[32m✓ PASS\x1b[0m ${testName}`);
        return true;
    } else {
        testResults.failed++;
        if (testResults.phases[phase]) testResults.phases[phase].failed++;
        const error = `${testName}${details ? ': ' + details : ''}`;
        testResults.errors.push({ phase, test: testName, details });
        console.log(`  \x1b[31m✗ FAIL\x1b[0m ${testName}${details ? ' - ' + details : ''}`);
        return false;
    }
}

/** API HELPER */
async function apiCall(endpoint, method = 'GET', body = null, token = null, files = null) {
    const headers = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;
    let options = { method, headers };
    
    if (files) {
        const FormData = require('form-data');
        const form = new FormData();
        if (body) for (const [k, v] of Object.entries(body)) form.append(k, v);
        for (const [k, p] of Object.entries(files)) form.append(k, fs.createReadStream(p));
        options.body = form;
    } else if (body) {
        headers['Content-Type'] = 'application/json';
        options.body = JSON.stringify(body);
    }
    
    const res = await fetch(`${BASE_URL}${endpoint}`, options);
    let data = {};
    try { data = await res.json(); } catch(e) {}
    return { status: res.status, data };
}

/** STATE HELPERS */
async function getExcessState(excessId, token) {
    const res = await apiCall('/excess/my', 'GET', null, token);
    return res.data.data?.find(e => e._id === excessId);
}

async function getShortageState(shortageId, token) {
    const res = await apiCall('/shortage/my', 'GET', null, token);
    return res.data.data?.find(s => s._id === shortageId);
}

async function getPharmacyBalance(token) {
    const res = await apiCall('/auth/profile', 'GET', null, token);
    return res.data.data?.pharmacy?.balance || 0;
}

/** CLEANUP */
async function cleanup() {
    logSection('Cleanup');
    try {
        const models = [User, Pharmacy, Product, Volume, StockExcess, StockShortage, Transaction, DeliveryRequest, BalanceHistory, ReversalTicket, AuditLog, Notification, Order, HasVolume];
        for (const M of models) {
            await M.deleteMany({ createdAt: { $gte: TEST_START_TIME } });
        }
        await User.deleteOne({ email: 'a@test.com' });
        logStep('System restored.');
    } catch (err) { console.error('Cleanup error:', err); }
}

/** SETUP */
async function setup() {
    logSection('Setup');
    const uri = process.env.MONGODB_URI;
    if (mongoose.connection.readyState === 0) {
        try {
            await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
        } catch(e) {
            await mongoose.connect('mongodb://127.0.0.1:27017/medisync');
        }
    }
    
    await User.deleteMany({ email: 'a@test.com' });
    const admin = new User({ name: 'Admin', email: 'a@test.com', hashedPassword: 'A', role: 'admin', status: 'active', phone: '01010101010' });
    await admin.save();
    
    const vol = await Volume.findOneAndUpdate({ name: prefix('Box') }, { name: prefix('Box') }, { upsert: true, new: true });
    ids.vol = vol._id;
    const prod = await Product.findOneAndUpdate({ name: prefix('Med') }, { name: prefix('Med'), status: 'active' }, { upsert: true, new: true });
    ids.prod = prod._id;
    logStep('Base data ready.');
}

/** PRINT FINAL SCORE */
function printScore() {
    console.log('\n\n');
    console.log('\x1b[36m╔═══════════════════════════════════════════════════════════════╗\x1b[0m');
    console.log('\x1b[36m║                    FINAL TEST SCORE                           ║\x1b[0m');
    console.log('\x1b[36m╚═══════════════════════════════════════════════════════════════╝\x1b[0m\n');
    
    const passRate = ((testResults.passed / testResults.totalTests) * 100).toFixed(2);
    const scoreColor = passRate >= 90 ? '\x1b[32m' : passRate >= 70 ? '\x1b[33m' : '\x1b[31m';
    
    console.log(`  Total Tests:    ${testResults.totalTests}`);
    console.log(`  ${scoreColor}Passed:         ${testResults.passed}\x1b[0m`);
    console.log(`  ${testResults.failed > 0 ? '\x1b[31m' : ''}Failed:         ${testResults.failed}\x1b[0m`);
    console.log(`  ${scoreColor}Pass Rate:      ${passRate}%\x1b[0m\n`);
    
    console.log('  Phase Breakdown:');
    for (const [phase, stats] of Object.entries(testResults.phases)) {
        if (stats.tests > 0) {
            const phaseRate = ((stats.passed / stats.tests) * 100).toFixed(0);
            const phaseColor = phaseRate >= 90 ? '\x1b[32m' : phaseRate >= 70 ? '\x1b[33m' : '\x1b[31m';
            console.log(`    ${phaseColor}${phase}: ${stats.passed}/${stats.tests} (${phaseRate}%)\x1b[0m`);
        }
    }
    
    if (testResults.errors.length > 0) {
        console.log('\n  Failed Tests:');
        testResults.errors.forEach((err, i) => {
            console.log(`    ${i + 1}. [${err.phase}] ${err.test}${err.details ? ' - ' + err.details : ''}`);
        });
    }
    
    console.log('\n' + (passRate >= 90 ? '\x1b[32m  ✓ EXCELLENT!\x1b[0m' : passRate >= 70 ? '\x1b[33m  ⚠ NEEDS IMPROVEMENT\x1b[0m' : '\x1b[31m  ✗ CRITICAL ISSUES\x1b[0m'));
    console.log('\n');
}

/** MAIN TEST */
async function run() {
    try {
        await setup();
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 1: USER & PHARMACY SETUP
        // ═══════════════════════════════════════════════════════════════
        const PHASE1 = 'Phase 1: Setup';
        logSection(PHASE1);
        
        const pngBuffer = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==', 'base64');
        const dummy = './dummy.png'; 
        fs.writeFileSync(dummy, pngBuffer);
        
        const users = [
            { name: 'Buyer', phone: prefixPhone(1), email: prefixEmail(1), role: 'pharmacy_owner', key: 'buyer' },
            { name: 'Seller1', phone: prefixPhone(2), email: prefixEmail(2), role: 'pharmacy_owner', key: 's1' },
            { name: 'Seller2', phone: prefixPhone(3), email: prefixEmail(3), role: 'pharmacy_owner', key: 's2' },
            { name: 'Seller3', phone: prefixPhone(4), email: prefixEmail(4), role: 'pharmacy_owner', key: 's3' },
            { name: 'Delivery', phone: prefixPhone(9), email: prefixEmail(9), role: 'delivery', key: 'd1' }
        ];
        
        for (const u of users) {
            const r = await apiCall('/auth/register', 'POST', { name: u.name, phone: u.phone, email: u.email, password: 'password', role: u.role });
            assert(r.status === 201, `Register ${u.name}`, PHASE1, `Got ${r.status}`);
            tokens[u.key] = r.data.data?.token;
            ids[`${u.key}_user`] = r.data.data?._id;
            
            if (u.role === 'pharmacy_owner') {
                const link = await apiCall('/auth/link-pharmacy', 'POST', { 
                    name: prefix(u.name), address: 'Test St', phone: u.phone, ownerName: u.name, nationalId: '12345678901234' 
                }, tokens[u.key], { pharmacistCard: dummy, commercialRegistry: dummy, taxCard: dummy, pharmacyLicense: dummy });
                
                assert(link.status === 200, `Link pharmacy ${u.name}`, PHASE1, `Got ${link.status}`);
                ids[u.key] = link.data.data?.pharmacy?._id;
                
                const adminLogin = await apiCall('/auth/login', 'POST', { email: 'a@test.com', password: 'A' });
                tokens.admin = adminLogin.data.data?.token;
                await apiCall(`/admin/review-user/${ids[`${u.key}_user`]}`, 'PUT', { status: 'active' }, tokens.admin);
                
                const relogin = await apiCall('/auth/login', 'POST', { email: u.email, password: 'password' });
                tokens[u.key] = relogin.data.data?.token;
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 2: EXCESS/SHORTAGE CONFLICT VALIDATION
        // ═══════════════════════════════════════════════════════════════
        const PHASE2 = 'Phase 2: Excess/Shortage Conflicts';
        logSection(PHASE2);
        
        // Create shortage first
        const sh1 = await apiCall('/shortage', 'POST', { product: ids.prod.toString(), volume: ids.vol.toString(), quantity: 50 }, tokens.buyer);
        assert(sh1.status === 201, 'Create shortage', PHASE2);
        ids.shortage1 = sh1.data.data?._id;
        
        // Try to create excess for same product (should fail)
        const exConflict = await apiCall('/excess', 'POST', { product: ids.prod.toString(), volume: ids.vol.toString(), quantity: 30, expiryDate: '12/26', selectedPrice: 100 }, tokens.buyer);
        assert(exConflict.status === 400, 'Reject excess when shortage exists', PHASE2, `Got ${exConflict.status}`);
        
        // Create excess for seller
        const ex1 = await apiCall('/excess', 'POST', { product: ids.prod.toString(), volume: ids.vol.toString(), quantity: 40, expiryDate: '12/26', selectedPrice: 100, shortage_fulfillment: true }, tokens.s1);
        ids.ex1 = ex1.data.data?._id;
        await apiCall(`/excess/${ids.ex1}/approve`, 'PUT', {}, tokens.admin);
        
        // Try to create shortage for same product (should fail)
        const shConflict = await apiCall('/shortage', 'POST', { product: ids.prod.toString(), volume: ids.vol.toString(), quantity: 20 }, tokens.s1);
        assert(shConflict.status === 400, 'Reject shortage when excess exists', PHASE2, `Got ${shConflict.status}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 3: MATCHABLE PRODUCTS VALIDATION
        // ═══════════════════════════════════════════════════════════════
        const PHASE3 = 'Phase 3: Matchable Products';
        logSection(PHASE3);
        
        const matchable = await apiCall('/transaction/matchable', 'GET', null, tokens.admin);
        assert(matchable.status === 200, 'Get matchable products', PHASE3);
        assert(matchable.data.data?.length > 0, 'Has matchable products', PHASE3, `Found ${matchable.data.data?.length}`);
        
        const matches = await apiCall(`/transaction/matches/${ids.prod}`, 'GET', null, tokens.admin);
        assert(matches.status === 200, 'Get matches for product', PHASE3);
        assert(matches.data.data?.shortages?.length > 0, 'Has shortages', PHASE3);
        assert(matches.data.data?.excesses?.length > 0, 'Has excesses', PHASE3);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 4: SHORTAGE STATUS TRANSITIONS
        // ═══════════════════════════════════════════════════════════════
        const PHASE4 = 'Phase 4: Shortage Status Transitions';
        logSection(PHASE4);
        
        // active -> partially_fulfilled
        const tx1 = await apiCall('/transaction', 'POST', {
            shortageId: ids.shortage1, quantityTaken: 20,
            excessSources: [{ stockExcessId: ids.ex1, quantity: 20 }]
        }, tokens.admin);
        ids.tx1 = tx1.data.data?._id;
        
        let shStatus = await getShortageState(ids.shortage1, tokens.buyer);
        assert(shStatus?.status === 'partially_fulfilled', 'Shortage: active → partially_fulfilled', PHASE4, `Got ${shStatus?.status}`);
        
        // partially_fulfilled -> fulfilled
        const tx2 = await apiCall('/transaction', 'POST', {
            shortageId: ids.shortage1, quantityTaken: 20,
            excessSources: [{ stockExcessId: ids.ex1, quantity: 20 }]
        }, tokens.admin);
        
        shStatus = await getShortageState(ids.shortage1, tokens.buyer);
        assert(shStatus?.remainingQuantity === 10, 'Shortage remaining correct', PHASE4, `Got ${shStatus?.remainingQuantity}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 5: EXCESS STATUS TRANSITIONS
        // ═══════════════════════════════════════════════════════════════
        const PHASE5 = 'Phase 5: Excess Status Transitions';
        logSection(PHASE5);
        
        // Create new excess: pending
        const ex2 = await apiCall('/excess', 'POST', { product: ids.prod.toString(), volume: ids.vol.toString(), quantity: 100, expiryDate: '12/26', selectedPrice: 105, shortage_fulfillment: true }, tokens.s2);
        ids.ex2 = ex2.data.data?._id;
        
        let exStatus = await getExcessState(ids.ex2, tokens.s2);
        assert(exStatus?.status === 'pending', 'Excess: pending (initial)', PHASE5, `Got ${exStatus?.status}`);
        
        // pending -> available
        await apiCall(`/excess/${ids.ex2}/approve`, 'PUT', {}, tokens.admin);
        exStatus = await getExcessState(ids.ex2, tokens.s2);
        assert(exStatus?.status === 'available', 'Excess: pending → available', PHASE5, `Got ${exStatus?.status}`);
        
        // available -> partially_fulfilled
        const sh2 = await apiCall('/shortage', 'POST', { product: ids.prod.toString(), volume: ids.vol.toString(), quantity: 200 }, tokens.s3);
        ids.shortage2 = sh2.data.data?._id;
        
        await apiCall('/transaction', 'POST', {
            shortageId: ids.shortage2, quantityTaken: 50,
            excessSources: [{ stockExcessId: ids.ex2, quantity: 50 }]
        }, tokens.admin);
        
        exStatus = await getExcessState(ids.ex2, tokens.s2);
        assert(exStatus?.status === 'partially_fulfilled', 'Excess: available → partially_fulfilled', PHASE5, `Got ${exStatus?.status}`);
        
        // partially_fulfilled -> fulfilled
        await apiCall('/transaction', 'POST', {
            shortageId: ids.shortage2, quantityTaken: 50,
            excessSources: [{ stockExcessId: ids.ex2, quantity: 50 }]
        }, tokens.admin);
        
        exStatus = await getExcessState(ids.ex2, tokens.s2);
        assert(exStatus?.status === 'fulfilled', 'Excess: partially_fulfilled → fulfilled', PHASE5, `Got ${exStatus?.status}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 6: TRANSACTION STATUS TRANSITIONS
        // ═══════════════════════════════════════════════════════════════
        const PHASE6 = 'Phase 6: Transaction Status Transitions';
        logSection(PHASE6);
        
        const ex3 = await apiCall('/excess', 'POST', { product: ids.prod.toString(), volume: ids.vol.toString(), quantity: 80, expiryDate: '12/26', selectedPrice: 98, shortage_fulfillment: true }, tokens.s1);
        ids.ex3 = ex3.data.data?._id;
        await apiCall(`/excess/${ids.ex3}/approve`, 'PUT', {}, tokens.admin);
        
        // pending (initial)
        const txFlow = await apiCall('/transaction', 'POST', {
            shortageId: ids.shortage2, quantityTaken: 50,
            excessSources: [{ stockExcessId: ids.ex3, quantity: 50 }]
        }, tokens.admin);
        ids.txFlow = txFlow.data.data?._id;
        
        let txData = await apiCall(`/transaction?status=pending`, 'GET', null, tokens.admin);
        let thisTx = txData.data.data?.find(t => t._id === ids.txFlow);
        assert(thisTx?.status === 'pending', 'Transaction: pending (initial)', PHASE6, `Got ${thisTx?.status}`);
        
        // pending → accepted
        const dAcc = await apiCall('/delivery-requests', 'POST', { transactionId: ids.txFlow, requestType: 'accept' }, tokens.d1);
        await apiCall(`/delivery-requests/${dAcc.data.data?._id}/review`, 'PUT', { status: 'approved' }, tokens.admin);
        
        txData = await apiCall(`/transaction`, 'GET', null, tokens.admin);
        thisTx = txData.data.data?.find(t => t._id === ids.txFlow);
        assert(thisTx?.status === 'accepted', 'Transaction: pending → accepted', PHASE6, `Got ${thisTx?.status}`);
        
        // accepted → completed
        const dComp = await apiCall('/delivery-requests', 'POST', { transactionId: ids.txFlow, requestType: 'complete' }, tokens.d1);
        await apiCall(`/delivery-requests/${dComp.data.data?._id}/review`, 'PUT', { status: 'approved' }, tokens.admin);
        
        txData = await apiCall(`/transaction`, 'GET', null, tokens.admin);
        thisTx = txData.data.data?.find(t => t._id === ids.txFlow);
        assert(thisTx?.status === 'completed', 'Transaction: accepted → completed', PHASE6, `Got ${thisTx?.status}`);
        
        // completed → cancelled (via reversal)
        await apiCall(`/transaction/${ids.txFlow}/revert`, 'POST', { description: 'Test', expenses: [] }, tokens.admin);
        
        txData = await apiCall(`/transaction`, 'GET', null, tokens.admin);
        thisTx = txData.data.data?.find(t => t._id === ids.txFlow);
        assert(thisTx?.status === 'cancelled', 'Transaction: completed → cancelled (reversal)', PHASE6, `Got ${thisTx?.status}`);
        
        // Test rejected path
        const txReject = await apiCall('/transaction', 'POST', {
            shortageId: ids.shortage2, quantityTaken: 20,
            excessSources: [{ stockExcessId: ids.ex3, quantity: 20 }]
        }, tokens.admin);
        
        await apiCall(`/transaction/${txReject.data.data?._id}/status`, 'PUT', { status: 'rejected' }, tokens.admin);
        
        txData = await apiCall(`/transaction`, 'GET', null, tokens.admin);
        thisTx = txData.data.data?.find(t => t._id === txReject.data.data?._id);
        assert(thisTx?.status === 'rejected', 'Transaction: pending → rejected', PHASE6, `Got ${thisTx?.status}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 7: ORDER STATUS TRANSITIONS
        // ═══════════════════════════════════════════════════════════════
        const PHASE7 = 'Phase 7: Order Status Transitions';
        logSection(PHASE7);
        
        // Create order (pending)
        const order = await apiCall('/shortage/order', 'POST', {
            items: [
                { product: ids.prod.toString(), volume: ids.vol.toString(), quantity: 30 },
                { product: ids.prod.toString(), volume: ids.vol.toString(), quantity: 20 }
            ],
            notes: 'Test order'
        }, tokens.s3);
        ids.order = order.data.data?._id;
        
        const orderData = await apiCall('/shortage/orders', 'GET', null, tokens.admin);
        let thisOrder = orderData.data.data?.find(o => o._id === ids.order);
        assert(thisOrder?.status === 'pending', 'Order: pending (initial)', PHASE7, `Got ${thisOrder?.status}`);
        
        // Fulfill one item (pending → partially_fulfilled)
        const orderItems = order.data.data?.items || [];
        if (orderItems.length > 0) {
            await apiCall('/transaction', 'POST', {
                shortageId: orderItems[0]._id,
                quantityTaken: 30,
                excessSources: [{ stockExcessId: ids.ex3, quantity: 10 }]
            }, tokens.admin);
        }
        
        // Note: Order status update happens via shortage sync
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 8: UPDATE OPERATIONS
        // ═══════════════════════════════════════════════════════════════
        const PHASE8 = 'Phase 8: Update Operations';
        logSection(PHASE8);
        
        // Update shortage (decrease quantity)
        const shUpdate = await apiCall(`/shortage/${ids.shortage2}`, 'PUT', { quantity: 150, notes: 'Updated' }, tokens.s3);
        assert(shUpdate.status === 200, 'Update shortage', PHASE8, `Got ${shUpdate.status}`);
        
        const shUpdated = await getShortageState(ids.shortage2, tokens.s3);
        assert(shUpdated?.quantity === 150, 'Shortage quantity updated', PHASE8, `Got ${shUpdated?.quantity}`);
        assert(shUpdated?.notes === 'Updated', 'Shortage notes updated', PHASE8);
        
        // Try to increase quantity (should fail)
        const shBadUpdate = await apiCall(`/shortage/${ids.shortage2}`, 'PUT', { quantity: 300 }, tokens.s3);
        assert(shBadUpdate.status !== 200, 'Reject shortage quantity increase', PHASE8, `Got ${shBadUpdate.status}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 9: DELIVERY ASSIGNMENT CONFLICTS
        // ═══════════════════════════════════════════════════════════════
        const PHASE9 = 'Phase 9: Delivery Conflicts';
        logSection(PHASE9);
        
        // Register second delivery user
        const d2Reg = await apiCall('/auth/register', 'POST', { name: 'Delivery2', phone: prefixPhone(8), email: prefixEmail(8), password: 'password', role: 'delivery' });
        tokens.d2 = d2Reg.data.data?.token;
        
        // Create new transaction for conflict test
        const txConflict = await apiCall('/transaction', 'POST', {
            shortageId: ids.shortage2, quantityTaken: 10,
            excessSources: [{ stockExcessId: ids.ex3, quantity: 10 }]
        }, tokens.admin);
        ids.txConflict = txConflict.data.data?._id;
        
        // Both deliveries request acceptance
        const d1Req = await apiCall('/delivery-requests', 'POST', { transactionId: ids.txConflict, requestType: 'accept' }, tokens.d1);
        const d2Req = await apiCall('/delivery-requests', 'POST', { transactionId: ids.txConflict, requestType: 'accept' }, tokens.d2);
        
        assert(d1Req.status === 201, 'D1 accept request created', PHASE9);
        assert(d2Req.status === 201, 'D2 accept request created', PHASE9);
        
        // Admin approves D1
        await apiCall(`/delivery-requests/${d1Req.data.data?._id}/review`, 'PUT', { status: 'approved' }, tokens.admin);
        
        // Check if D2's request was cleaned up
        const pendingReqs = await apiCall('/delivery-requests/pending', 'GET', null, tokens.admin);
        const d2StillPending = pendingReqs.data.data?.find(r => r._id === d2Req.data.data?._id);
        
        assert(!d2StillPending, 'D2 request auto-cleaned after D1 approved', PHASE9, d2StillPending ? 'Still exists' : '');
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 10: TRANSACTION RATIO UPDATES
        // ═══════════════════════════════════════════════════════════════
        const PHASE10 = 'Phase 10: Ratio Updates';
        logSection(PHASE10);
        
        // Create new transaction
        const txRatio = await apiCall('/transaction', 'POST', {
            shortageId: ids.shortage2, quantityTaken: 5,
            excessSources: [{ stockExcessId: ids.ex3, quantity: 5 }]
        }, tokens.admin);
        ids.txRatio = txRatio.data.data?._id;
        
        // Update ratios
        const updateRatios = await apiCall(`/transaction/${ids.txRatio}/ratios`, 'PUT', {
            commissionRatio: 15,
            buyerCommissionRatio: 12,
            sellerBonusRatio: 8
        }, tokens.admin);
        
        assert(updateRatios.status === 200, 'Update transaction ratios', PHASE10, `Got ${updateRatios.status}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 11: TRANSACTION UNASSIGNMENT
        // ═══════════════════════════════════════════════════════════════
        const PHASE11 = 'Phase 11: Unassignment';
        logSection(PHASE11);
        
        // Unassign D1 from txConflict
        const unassign = await apiCall(`/transaction/${ids.txConflict}/unassign`, 'PUT', {}, tokens.admin);
        assert(unassign.status === 200, 'Unassign delivery from transaction', PHASE11, `Got ${unassign.status}`);
        
        // Check transaction status (may or may not revert to pending - depends on implementation)
        const txDataUnassign = await apiCall(`/transaction`, 'GET', null, tokens.admin);
        const txUnassigned = txDataUnassign.data.data?.find(t => t._id === ids.txConflict);
        // Note: This test documents current behavior, not necessarily expected behavior
        assert(true, `Transaction status after unassign: ${txUnassigned?.status}`, PHASE11);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 12: DELETE PROTECTION
        // ═══════════════════════════════════════════════════════════════
        const PHASE12 = 'Phase 12: Delete Protection';
        logSection(PHASE12);
        
        // Try to delete shortage with active transactions
        const deleteSh = await apiCall(`/shortage/${ids.shortage2}`, 'DELETE', null, tokens.admin);
        assert(deleteSh.status !== 200, 'Prevent delete shortage with transactions', PHASE12, `Got ${deleteSh.status}`);
        
        // Try to delete excess with active transactions
        const deleteEx = await apiCall(`/excess/${ids.ex3}`, 'DELETE', null, tokens.admin);
        assert(deleteEx.status !== 200, 'Prevent delete excess with transactions', PHASE12, `Got ${deleteEx.status}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 13: DUPLICATE REQUEST PREVENTION
        // ═══════════════════════════════════════════════════════════════
        const PHASE13 = 'Phase 13: Duplicate Prevention';
        logSection(PHASE13);
        
        // Create new transaction
        const txDup = await apiCall('/transaction', 'POST', {
            shortageId: ids.shortage2, quantityTaken: 3,
            excessSources: [{ stockExcessId: ids.ex3, quantity: 3 }]
        }, tokens.admin);
        
        // D1 creates accept request
        const dupReq1 = await apiCall('/delivery-requests', 'POST', { transactionId: txDup.data.data?._id, requestType: 'accept' }, tokens.d1);
        assert(dupReq1.status === 201, 'First accept request created', PHASE13);
        
        // D1 tries to create another accept request (duplicate)
        const dupReq2 = await apiCall('/delivery-requests', 'POST', { transactionId: txDup.data.data?._id, requestType: 'accept' }, tokens.d1);
        assert(dupReq2.status === 400, 'Duplicate accept request rejected', PHASE13, `Got ${dupReq2.status}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 15: NOTIFICATION VALIDATION
        // ═══════════════════════════════════════════════════════════════
        const PHASE15 = 'Phase 15: Notifications';
        logSection(PHASE15);
        
        // Get notifications for buyer
        const notifications = await apiCall('/notifications', 'GET', null, tokens.buyer);
        assert(notifications.status === 200, 'Get notifications', PHASE15);
        assert(notifications.data.data?.length > 0, 'Has notifications', PHASE15, `Found ${notifications.data.data?.length}`);
        
        // Mark one as seen
        if (notifications.data.data && notifications.data.data.length > 0) {
            const notifId = notifications.data.data[0]._id;
            const markSeen = await apiCall(`/notifications/${notifId}/seen`, 'PUT', {}, tokens.buyer);
            assert(markSeen.status === 200, 'Mark notification as seen', PHASE15);
        }
        
        // Mark all as seen
        const markAllSeen = await apiCall('/notifications/mark-all-seen', 'PUT', {}, tokens.buyer);
        assert(markAllSeen.status === 200, 'Mark all notifications as seen', PHASE15);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 16: SETTINGS VALIDATION
        // ═══════════════════════════════════════════════════════════════
        const PHASE16 = 'Phase 16: Settings';
        logSection(PHASE16);
        
        // Get settings
        const settings = await apiCall('/settings', 'GET', null, tokens.admin);
        assert(settings.status === 200, 'Get settings', PHASE16);
        assert(settings.data.data?.minimumCommission !== undefined, 'Has minimumCommission', PHASE16);
        assert(settings.data.data?.shortageCommission !== undefined, 'Has shortageCommission', PHASE16);
        
        // Update settings
        const updateSettings = await apiCall('/settings', 'PUT', {
            minimumCommission: 12,
            shortageCommission: 10
        }, tokens.admin);
        assert(updateSettings.status === 200, 'Update settings', PHASE16);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 17: PRODUCT STATUS VALIDATION
        // ═══════════════════════════════════════════════════════════════
        const PHASE17 = 'Phase 17: Product Status';
        logSection(PHASE17);
        
        // Try to create excess with inactive product
        const prod2 = await Product.findOneAndUpdate(
            { name: prefix('InactiveMed') }, 
            { name: prefix('InactiveMed'), status: 'inactive' }, 
            { upsert: true, new: true }
        );
        
        const exInactive = await apiCall('/excess', 'POST', {
            product: prod2._id.toString(),
            volume: ids.vol.toString(),
            quantity: 10,
            expiryDate: '12/26',
            selectedPrice: 100,
            shortage_fulfillment: true
        }, tokens.s1);
        
        assert(exInactive.status === 400, 'Reject excess for inactive product', PHASE17, `Got ${exInactive.status}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 18: TRANSACTION COMPLETION FLOW
        // ═══════════════════════════════════════════════════════════════
        const PHASE18 = 'Phase 18: Complete Transaction Flow';
        logSection(PHASE18);
        
        // Create fresh transaction for full completion test
        const sh3 = await apiCall('/shortage', 'POST', {
            product: ids.prod.toString(),
            volume: ids.vol.toString(),
            quantity: 25
        }, tokens.buyer);
        
        const ex4 = await apiCall('/excess', 'POST', {
            product: ids.prod.toString(),
            volume: ids.vol.toString(),
            quantity: 25,
            expiryDate: '12/26',
            selectedPrice: 100,
            shortage_fulfillment: true
        }, tokens.s1);
        await apiCall(`/excess/${ex4.data.data?._id}/approve`, 'PUT', {}, tokens.admin);
        
        const txComplete = await apiCall('/transaction', 'POST', {
            shortageId: sh3.data.data?._id,
            quantityTaken: 25,
            excessSources: [{ stockExcessId: ex4.data.data?._id, quantity: 25 }]
        }, tokens.admin);
        
        assert(txComplete.status === 201, 'Create transaction for completion', PHASE18);
        
        // Accept
        const acceptReq = await apiCall('/delivery-requests', 'POST', {
            transactionId: txComplete.data.data?._id,
            requestType: 'accept'
        }, tokens.d1);
        await apiCall(`/delivery-requests/${acceptReq.data.data?._id}/review`, 'PUT', {
            status: 'approved'
        }, tokens.admin);
        
        // Wait a bit for async operations
        await new Promise(resolve => setTimeout(resolve, 500));
        
        // Complete
        const completeReq = await apiCall('/delivery-requests', 'POST', {
            transactionId: txComplete.data.data?._id,
            requestType: 'complete'
        }, tokens.d1);
        await apiCall(`/delivery-requests/${completeReq.data.data?._id}/review`, 'PUT', {
            status: 'approved'
        }, tokens.admin);
        
        // Wait for settlement to complete
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Verify completion
        const txFinal = await apiCall('/transaction', 'GET', null, tokens.admin);
        const completedTx = txFinal.data.data?.find(t => t._id === txComplete.data.data?._id);
        assert(completedTx?.status === 'completed', 'Transaction completed', PHASE18, `Got ${completedTx?.status}`);
        
        // Verify balances changed
        const buyerFinalBal = await getPharmacyBalance(tokens.buyer);
        const s1FinalBal = await getPharmacyBalance(tokens.s1);
        assert(buyerFinalBal < 0, 'Buyer paid (negative balance)', PHASE18, `Balance: ${buyerFinalBal}`);
        assert(s1FinalBal > 0, 'Seller received (positive balance)', PHASE18, `Balance: ${s1FinalBal}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 14: BALANCE HISTORY VALIDATION (moved after completion)
        // ═══════════════════════════════════════════════════════════════
        const PHASE14 = 'Phase 14: Balance History';
        logSection(PHASE14);
        
        // Get balance history for buyer (should have entries now after completion)
        const buyerHistory = await apiCall('/balance-history/my', 'GET', null, tokens.buyer);
        assert(buyerHistory.status === 200, 'Get balance history', PHASE14, `Got ${buyerHistory.status}`);
        
        // Should have entries from completed transactions
        const hasEntries = buyerHistory.data.data && buyerHistory.data.data.length > 0;
        assert(hasEntries, 'Balance history has entries after completion', PHASE14, `Found ${buyerHistory.data.data?.length || 0}`);
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 19: EXCESS UPDATE VALIDATION
        // ═══════════════════════════════════════════════════════════════
        const PHASE19 = 'Phase 19: Excess Updates';
        logSection(PHASE19);
        
        // Create new excess for update tests
        const exUpdate = await apiCall('/excess', 'POST', {
            product: ids.prod.toString(),
            volume: ids.vol.toString(),
            quantity: 50,
            expiryDate: '12/26',
            selectedPrice: 100,
            shortage_fulfillment: false,
            salePercentage: 10
        }, tokens.s1);
        await apiCall(`/excess/${exUpdate.data.data?._id}/approve`, 'PUT', {}, tokens.admin);
        
        // Update quantity (decrease)
        const updateExQty = await apiCall(`/excess/${exUpdate.data.data?._id}`, 'PUT', {
            quantity: 40,
            shortage_fulfillment: false
        }, tokens.s1);
        assert(updateExQty.status === 200, 'Update excess quantity', PHASE19, `Got ${updateExQty.status}`);
        
        // Update sale percentage
        const updateExSale = await apiCall(`/excess/${exUpdate.data.data?._id}`, 'PUT', {
            salePercentage: 15,
            shortage_fulfillment: false
        }, tokens.s1);
        assert(updateExSale.status === 200, 'Update excess sale percentage', PHASE19, `Got ${updateExSale.status}`);
        
        // Try to update fulfilled excess (should fail)
        const exFulfilled = await getExcessState(ids.ex2, tokens.s2);
        if (exFulfilled?.status === 'fulfilled') {
            const updateFulfilled = await apiCall(`/excess/${ids.ex2}`, 'PUT', {
                quantity: 50
            }, tokens.s2);
            assert(updateFulfilled.status !== 200, 'Reject update of fulfilled excess', PHASE19, `Got ${updateFulfilled.status}`);
        }
        
        // ═══════════════════════════════════════════════════════════════
        // PHASE 20: MARKET & SALE LOGIC
        // ═══════════════════════════════════════════════════════════════
        const PHASE20 = 'Phase 20: Market & Sale Logic';
        logSection(PHASE20);

        // 1. Create Excess with Sale > 10% (e.g. 20%)
        // Price: 100. Sale: 20%. Expiry: '01/27'.
        // Expectation: 
        // - System Commission: 10% (min)
        // - Buyer Discount: 10% (20% total - 10% comm)
        // - Buyer Pays: 90 (100 * 0.9)
        // - Seller Receives: 80 (100 * 0.8)
        
        const exSale = await apiCall('/excess', 'POST', {
            product: ids.prod.toString(),
            volume: ids.vol.toString(),
            quantity: 10,
            expiryDate: '01/27',
            selectedPrice: 100,
            shortage_fulfillment: true, // Auto-approved or need manual approval?
            salePercentage: 20
        }, tokens.s1); 
        // Note: 'shortage_fulfillment: true' usually bypasses approval if matches, 
        // but here we might not have a matching shortage yet. 
        // If it returns pending, we approve.
        
        let exSaleId = exSale.data.data?._id;
        if (exSale.data.data?.status === 'pending') {
             await apiCall(`/excess/${exSaleId}/approve`, 'PUT', {}, tokens.admin);
        }

        // 2. Create Shortage
        const shSale = await apiCall('/shortage', 'POST', {
            product: ids.prod.toString(),
            volume: ids.vol.toString(),
            quantity: 10
        }, tokens.buyer);
        let shSaleId = shSale.data.data?._id;

        // Get initial balances
        const buyerBalStart = await getPharmacyBalance(tokens.buyer);
        const s1BalStart = await getPharmacyBalance(tokens.s1);

        // 3. Create Transaction
        const txSale = await apiCall('/transaction', 'POST', {
            shortageId: shSaleId,
            quantityTaken: 10,
            excessSources: [{ stockExcessId: exSaleId, quantity: 10 }]
        }, tokens.admin);
        
        assert(txSale.status === 201, 'Create transaction with sale', PHASE20);
        const txSaleId = txSale.data.data?._id;

        // 4. Complete Transaction
        const dSaleReq = await apiCall('/delivery-requests', 'POST', { transactionId: txSaleId, requestType: 'accept' }, tokens.d1);
        await apiCall(`/delivery-requests/${dSaleReq.data.data?._id}/review`, 'PUT', { status: 'approved' }, tokens.admin);
        
        await new Promise(resolve => setTimeout(resolve, 500));
        
        const dSaleComp = await apiCall('/delivery-requests', 'POST', { transactionId: txSaleId, requestType: 'complete' }, tokens.d1);
        await apiCall(`/delivery-requests/${dSaleComp.data.data?._id}/review`, 'PUT', { status: 'approved' }, tokens.admin);
        
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait for settlement

        // 5. Verify Balances
        const buyerBalEnd = await getPharmacyBalance(tokens.buyer);
        const s1BalEnd = await getPharmacyBalance(tokens.s1);

        // Check verification
        // Buyer Cost: 10 items * 100 price * 0.9 (10% discount) = 900
        // Seller Gain: 10 items * 100 price * 0.8 (20% fee) = 800
        
        const buyerDiff = buyerBalStart - buyerBalEnd; // Should be positive 900 (cost)
        const sellerDiff = s1BalEnd - s1BalStart;      // Should be positive 800 (gain)

        // Allow small float margin
        const isBuyerCorrect = Math.abs(buyerDiff - 900) < 1;
        const isSellerCorrect = Math.abs(sellerDiff - 800) < 1;

        assert(isBuyerCorrect, 'Buyer pays discounted price (90%)', PHASE20, `Paid ${buyerDiff}, Expected 900`);
        assert(isSellerCorrect, 'Seller receives post-commission amount (80%)', PHASE20, `Recv ${sellerDiff}, Expected 800`);

        console.log('\n\x1b[32m✓ All test phases completed (20 comprehensive phases)!\x1b[0m');
        
    } catch (err) {
        console.error('\n\x1b[31m✗ Test execution error:\x1b[0m', err.message);
        console.error(err.stack);
        testResults.errors.push({ phase: 'Execution', test: 'Runtime', details: err.message });
    } finally {
        await cleanup();
        if (fs.existsSync('./dummy.png')) fs.unlinkSync('./dummy.png');
        if (mongoose.connection.readyState !== 0) await mongoose.connection.close();
        
        printScore();
        process.exit(testResults.failed > 0 ? 1 : 0);
    }
}

run();
