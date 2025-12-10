-- Remove icon and logo_url columns from clubs table
-- Clubs will display using logo images from storage bucket only

ALTER TABLE clubs DROP COLUMN IF EXISTS icon;
ALTER TABLE clubs DROP COLUMN IF EXISTS logo_url;

-- Note: Logo functionality will use storage bucket (profile-photos)
-- Logo images will be displayed using the club's uploaded image from storage
-- If no logo is uploaded, clubs will show a default placeholder icon in the UI
