#!/usr/bin/env node

/**
 * Health Check Script
 * Verifies that all AgriSupply services are operational
 * 
 * Usage: node scripts/healthcheck.js
 */

const https = require('https');
const http = require('http');
require('dotenv').config();

const checks = {
  api: {
    name: 'AgriSupply API',
    url: process.env.API_URL || 'http://localhost:3000',
    endpoint: '/health',
  },
  supabase: {
    name: 'Supabase',
    url: process.env.SUPABASE_URL,
    endpoint: '/rest/v1/',
    headers: {
      'apikey': process.env.SUPABASE_ANON_KEY,
    },
  },
};

async function checkHealth(config) {
  return new Promise((resolve) => {
    const url = new URL(config.endpoint, config.url);
    const protocol = url.protocol === 'https:' ? https : http;
    
    const options = {
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      method: 'GET',
      timeout: 10000,
      headers: config.headers || {},
    };

    const req = protocol.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        resolve({
          name: config.name,
          status: res.statusCode >= 200 && res.statusCode < 300 ? 'healthy' : 'unhealthy',
          statusCode: res.statusCode,
          responseTime: Date.now() - startTime,
        });
      });
    });

    req.on('error', (error) => {
      resolve({
        name: config.name,
        status: 'unhealthy',
        error: error.message,
        responseTime: Date.now() - startTime,
      });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({
        name: config.name,
        status: 'timeout',
        error: 'Request timed out',
        responseTime: 10000,
      });
    });

    const startTime = Date.now();
    req.end();
  });
}

async function main() {
  console.log('🏥 AgriSupply Health Check\n');
  console.log('='.repeat(60));

  const results = [];
  let allHealthy = true;

  for (const [key, config] of Object.entries(checks)) {
    if (!config.url) {
      console.log(`⚠️  ${config.name}: Not configured`);
      continue;
    }

    process.stdout.write(`Checking ${config.name}... `);
    const result = await checkHealth(config);
    results.push(result);

    if (result.status === 'healthy') {
      console.log(`✅ Healthy (${result.responseTime}ms)`);
    } else {
      console.log(`❌ ${result.status} - ${result.error || `Status: ${result.statusCode}`}`);
      allHealthy = false;
    }
  }

  console.log('='.repeat(60));

  if (allHealthy) {
    console.log('\n✅ All services are healthy!\n');
    process.exit(0);
  } else {
    console.log('\n❌ Some services are unhealthy\n');
    process.exit(1);
  }
}

main();
