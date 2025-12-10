// Supabase Configuration
// Replace these with your actual Supabase credentials when ready
const SUPABASE_CONFIG = {
  url: 'https://nzkwqsbigkyvaxazfwgu.supabase.co', // e.g., 'https://xxxxx.supabase.co'
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56a3dxc2JpZ2t5dmF4YXpmd2d1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTg4NTgsImV4cCI6MjA4MDM3NDg1OH0.ZYyF95McgS3McU8zr7K3L2HHXkEHR1Acd0AmoTu5wL4' // Your anon/public key
};

// For development/prototype, the app will use mock data
// Set this to true once Supabase is configured
const USE_SUPABASE = true;

// Mock data configuration
const MOCK_CONFIG = {
  enabled: false,
  mockDelay: 1000 // Simulate API delay in milliseconds
};
