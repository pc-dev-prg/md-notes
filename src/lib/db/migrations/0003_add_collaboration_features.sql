-- Create note_collaborators table
CREATE TABLE note_collaborators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id UUID REFERENCES notes ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  permission_level TEXT NOT NULL DEFAULT 'view', -- 'view' or 'edit'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(note_id, user_id)
);

-- Enable RLS for note_collaborators
ALTER TABLE note_collaborators ENABLE ROW LEVEL SECURITY;

-- Allow note owners to manage collaborators
CREATE POLICY "Allow note owners to manage collaborators" ON note_collaborators
FOR ALL
USING (
  (SELECT user_id FROM notes WHERE id = note_id) = auth.uid()
);

-- Allow collaborators to see their own permissions
CREATE POLICY "Allow collaborators to see their own permissions" ON note_collaborators
FOR SELECT
USING (
  user_id = auth.uid()
);

-- Update RLS policy for notes to allow access to collaborators
DROP POLICY "Only allow users to access notes within their projects" ON notes;

CREATE POLICY "Allow users to access their own and shared notes" ON notes
FOR ALL
USING (
  -- User is the owner
  user_id = auth.uid() OR
  -- User is a collaborator
  id IN (SELECT note_id FROM note_collaborators WHERE user_id = auth.uid())
);
