-- Create notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES auth.users ON DELETE CASCADE,
  note_id UUID REFERENCES notes ON DELETE CASCADE,
  type TEXT NOT NULL, -- e.g., 'new_collaborator'
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Enable RLS for notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Allow users to access their own notifications
CREATE POLICY "Allow users to access their own notifications" ON notifications
FOR ALL
USING (
  user_id = auth.uid()
);
