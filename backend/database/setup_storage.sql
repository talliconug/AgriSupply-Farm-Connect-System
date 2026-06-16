-- ============================================
-- STORAGE BUCKETS SETUP FOR AGRISUPPLY
-- ============================================
-- Run this SQL script in your Supabase SQL Editor to create storage buckets
-- and set up the necessary policies for file uploads

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
    ('profile-photos', 'profile-photos', true),
    ('product-images', 'product-images', true),
    ('review-images', 'review-images', true),
    ('ai-images', 'ai-images', false),
    ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist (to allow re-running this script)
DROP POLICY IF EXISTS "Anyone can view public images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;

-- Storage policies
CREATE POLICY "Anyone can view public images"
    ON storage.objects FOR SELECT
    USING (bucket_id IN ('profile-photos', 'product-images', 'review-images'));

CREATE POLICY "Authenticated users can upload"
    ON storage.objects FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update own files"
    ON storage.objects FOR UPDATE
    USING (auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete own files"
    ON storage.objects FOR DELETE
    USING (auth.uid()::text = (storage.foldername(name))[1]);
