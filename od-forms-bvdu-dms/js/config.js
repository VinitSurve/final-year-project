// Supabase Configuration
// Replace these with your actual Supabase credentials when ready
const SUPABASE_CONFIG = {
  url: 'YOUR_SUPABASE_URL', // e.g., 'https://xxxxx.supabase.co'
  anonKey: 'YOUR_SUPABASE_ANON_KEY' // Your anon/public key
};

// For development/prototype, the app will use mock data
// Set this to true once Supabase is configured
const USE_SUPABASE = false;

// Mock data configuration
const MOCK_CONFIG = {
  enabled: true,
  mockDelay: 1000 // Simulate API delay in milliseconds
};
