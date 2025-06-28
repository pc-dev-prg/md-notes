-- Create note_history table
CREATE TABLE note_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  note_id UUID REFERENCES notes ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Enable RLS for note_history
ALTER TABLE note_history ENABLE ROW LEVEL SECURITY;

-- Allow users to view history for notes they have access to
CREATE POLICY "Allow users to view history for their notes" ON note_history
FOR SELECT
USING (
  note_id IN (SELECT id FROM notes WHERE auth.uid() = user_id)
);

-- Create a function to save note history
CREATE OR REPLACE FUNCTION public.save_note_history()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.note_history (note_id, title, content)
  VALUES (old.id, old.title, old.content);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger to save note history on update
CREATE TRIGGER on_note_update
  BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE PROCEDURE public.save_note_history();
