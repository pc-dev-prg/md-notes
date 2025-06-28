-- Add public sharing columns to notes table
ALTER TABLE notes ADD COLUMN is_public BOOLEAN DEFAULT FALSE;
ALTER TABLE notes ADD COLUMN public_id UUID UNIQUE DEFAULT gen_random_uuid();

-- Update RLS policy for notes to allow public access
DROP POLICY "Allow users to access their own and shared notes" ON notes;

CREATE POLICY "Allow users to access their own and shared notes" ON notes
FOR ALL
USING (
  -- User is the owner
  user_id = auth.uid() OR
  -- User is a collaborator
  id IN (SELECT note_id FROM note_collaborators WHERE user_id = auth.uid())
);

CREATE POLICY "Allow public read access to public notes" ON notes
FOR SELECT
USING (
  is_public = TRUE
);
