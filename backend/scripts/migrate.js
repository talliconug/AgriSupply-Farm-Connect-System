#!/usr/bin/env node

/**
 * Database Migration Script
 * Handles schema migrations for AgriSupply
 * 
 * Usage: 
 *   node scripts/migrate.js up     - Run pending migrations
 *   node scripts/migrate.js down   - Rollback last migration
 *   node scripts/migrate.js status - Show migration status
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const migrationsDir = path.join(__dirname, '../database/migrations');

// Ensure migrations table exists
async function ensureMigrationsTable() {
  const { error } = await supabase.rpc('exec_sql', {
    sql: `
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `
  });
  
  // If RPC doesn't exist, try direct query
  if (error) {
    console.log('Note: exec_sql RPC not available, using alternative method');
    // The table should be created manually or via Supabase dashboard
  }
}

// Get executed migrations
async function getExecutedMigrations() {
  const { data, error } = await supabase
    .from('migrations')
    .select('name')
    .order('executed_at', { ascending: true });

  if (error) {
    if (error.message.includes('does not exist')) {
      return [];
    }
    throw error;
  }

  return data.map(m => m.name);
}

// Get pending migrations
async function getPendingMigrations() {
  if (!fs.existsSync(migrationsDir)) {
    fs.mkdirSync(migrationsDir, { recursive: true });
    return [];
  }

  const files = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  const executed = await getExecutedMigrations();
  return files.filter(f => !executed.includes(f));
}

// Run migrations up
async function migrateUp() {
  console.log('Running migrations...\n');

  await ensureMigrationsTable();
  const pending = await getPendingMigrations();

  if (pending.length === 0) {
    console.log('No pending migrations.');
    return;
  }

  for (const migration of pending) {
    console.log(`Running: ${migration}`);

    const filePath = path.join(migrationsDir, migration);
    const sql = fs.readFileSync(filePath, 'utf8');

    // Execute via Supabase (this requires proper RLS setup or service role)
    const { error } = await supabase.rpc('exec_sql', { sql });

    if (error) {
      console.error(`Error running ${migration}:`, error);
      console.log('\nNote: For complex migrations, run SQL directly in Supabase SQL Editor');
      throw error;
    }

    // Record migration
    await supabase
      .from('migrations')
      .insert({ name: migration });

    console.log(`Completed: ${migration}`);
  }

  console.log(`\nRan ${pending.length} migration(s).`);
}

// Rollback last migration
async function migrateDown() {
  console.log('Rolling back last migration...\n');

  const executed = await getExecutedMigrations();
  if (executed.length === 0) {
    console.log('No migrations to rollback.');
    return;
  }

  const lastMigration = executed[executed.length - 1];
  const downFile = lastMigration.replace('.sql', '.down.sql');
  const downPath = path.join(migrationsDir, downFile);

  if (!fs.existsSync(downPath)) {
    console.error(`No rollback file found: ${downFile}`);
    console.log('Create a rollback file or rollback manually.');
    return;
  }

  console.log(`Rolling back: ${lastMigration}`);
  const sql = fs.readFileSync(downPath, 'utf8');

  const { error } = await supabase.rpc('exec_sql', { sql });

  if (error) {
    console.error(`Error rolling back ${lastMigration}:`, error);
    throw error;
  }

  // Remove migration record
  await supabase
    .from('migrations')
    .delete()
    .eq('name', lastMigration);

  console.log(`Rolled back: ${lastMigration}`);
}

// Show migration status
async function showStatus() {
  console.log('Migration Status\n');
  console.log('='.repeat(60));

  const executed = await getExecutedMigrations();

  if (!fs.existsSync(migrationsDir)) {
    console.log('No migrations directory found.');
    return;
  }

  const allMigrations = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql') && !f.endsWith('.down.sql'))
    .sort();

  for (const migration of allMigrations) {
    const status = executed.includes(migration) ? '✅ Executed' : '⏳ Pending';
    console.log(`${status}  ${migration}`);
  }

  console.log('='.repeat(60));
  console.log(`Total: ${allMigrations.length} | Executed: ${executed.length} | Pending: ${allMigrations.length - executed.length}`);
}

// Create new migration
async function createMigration(name) {
  if (!name) {
    console.error('Please provide a migration name');
    console.log('Usage: node scripts/migrate.js create <name>');
    return;
  }

  if (!fs.existsSync(migrationsDir)) {
    fs.mkdirSync(migrationsDir, { recursive: true });
  }

  const timestamp = new Date().toISOString().replace(/[-:T.]/g, '').slice(0, 14);
  const fileName = `${timestamp}_${name.replace(/\s+/g, '_').toLowerCase()}.sql`;
  const downFileName = `${timestamp}_${name.replace(/\s+/g, '_').toLowerCase()}.down.sql`;

  const upContent = `-- Migration: ${name}
-- Created: ${new Date().toISOString()}

-- Write your migration SQL here
`;

  const downContent = `-- Rollback: ${name}
-- Created: ${new Date().toISOString()}

-- Write your rollback SQL here
`;

  fs.writeFileSync(path.join(migrationsDir, fileName), upContent);
  fs.writeFileSync(path.join(migrationsDir, downFileName), downContent);

  console.log(`Created migration: ${fileName}`);
  console.log(`Created rollback:  ${downFileName}`);
}

// Main CLI
async function main() {
  const command = process.argv[2];
  const arg = process.argv[3];

  try {
    switch (command) {
      case 'up':
        await migrateUp();
        break;
      case 'down':
        await migrateDown();
        break;
      case 'status':
        await showStatus();
        break;
      case 'create':
        await createMigration(arg);
        break;
      default:
        console.log('AgriSupply Database Migration Tool\n');
        console.log('Usage:');
        console.log('  node scripts/migrate.js up              Run pending migrations');
        console.log('  node scripts/migrate.js down            Rollback last migration');
        console.log('  node scripts/migrate.js status          Show migration status');
        console.log('  node scripts/migrate.js create <name>   Create new migration');
    }
  } catch (error) {
    console.error('\nMigration error:', error.message);
    process.exit(1);
  }
}

main();
