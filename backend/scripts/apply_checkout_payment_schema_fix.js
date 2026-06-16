#!/usr/bin/env node

/**
 * Applies checkout/payment schema compatibility fix SQL using Supabase RPC exec_sql.
 * If exec_sql is unavailable, it prints clear manual instructions.
 */

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const sqlPath = path.join(__dirname, '..', 'database', 'manual_fix_checkout_payment.sql');

async function main() {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in backend/.env');
  }

  const sql = fs.readFileSync(sqlPath, 'utf8');

  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
  );

  console.log('Applying schema fix via rpc(exec_sql)...');
  const { error } = await supabase.rpc('exec_sql', { sql });

  if (error) {
    console.error('\nCould not apply automatically using rpc(exec_sql).');
    console.error('Reason:', error.message || error);
    console.error('\nRun this SQL manually in Supabase SQL Editor:');
    console.error('File:', sqlPath);
    process.exit(1);
  }

  console.log('Schema fix applied successfully.');
}

main().catch((err) => {
  console.error('Failed to apply schema fix:', err.message || err);
  process.exit(1);
});
