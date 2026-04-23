const XLSX = require('xlsx');
const path = require('path');

const filePath = 'd:\\MediSync\\backend\\src\\db\\Market Excesses Export_1774876534355.xlsx';
const workbook = XLSX.readFile(filePath);
const sheetName = workbook.SheetNames[0];
const worksheet = workbook.Sheets[sheetName];
const data = XLSX.utils.sheet_to_json(worksheet);

console.log('Headers:', Object.keys(data[0]));
console.log('First row:', JSON.stringify(data[0], null, 2));
console.log('Total rows:', data.length);
