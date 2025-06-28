<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import Sidebar from '$lib/components/Sidebar.svelte';
  import NoteEditor from '$lib/components/NoteEditor.svelte';
  import NotePreviewer from '$lib/components/NotePreviewer.svelte';
  import { sessionStore, projectsStore, selectedProjectStore } from '$lib/store';

  let session;
  sessionStore.subscribe((value) => {
    session = value;
  });

  let selectedProject;
  selectedProjectStore.subscribe((value) => {
    selectedProject = value;
  });

  let noteContent = '# Hello, Markdown!';
  let selectedNote = null;
  let isGuest = false;
  let saveTimeout;
  let saveStatus = 'Saved';

  onMount(async () => {
    if (session?.user?.id === 'guest') {
      isGuest = true;
    } else if (!session) {
      goto('/');
    }
  });

  const handleLogout = async () => {
    if (isGuest) {
      sessionStore.set(null);
      goto('/');
      return;
    }
    const { error } = await supabase.auth.signOut();
    if (error) alert(error.message);
  };

  function handleSelectNote(event) {
    selectedNote = event.detail;
    noteContent = selectedNote.content;
  }

  const createNewNote = async () => {
    if (!selectedProject) {
      alert('Please select a project first.');
      return;
    }

    const title = prompt('Enter note title:');
    if (!title) return;

    if (isGuest) {
      const newNote = {
        id: Math.random().toString(36).substring(2),
        title,
        content: '# New Note',
        project_id: selectedProject.id,
        folder_id: selectedProject.folders[0]?.id,
      };
      projectsStore.update((currentProjects) => {
        const projectIndex = currentProjects.findIndex((p) => p.id === selectedProject.id);
        currentProjects[projectIndex].notes.push(newNote);
        return currentProjects;
      });
      selectedNote = newNote;
      noteContent = newNote.content;
      return;
    }

    let folderId;
    if (selectedProject.folders.length === 0) {
      const { data: newFolder, error: folderError } = await supabase
        .from('folders')
        .insert({ name: 'General', project_id: selectedProject.id })
        .select()
        .single();

      if (folderError) {
        console.error('Error creating folder:', folderError);
        alert('Error creating folder.');
        return;
      }
      folderId = newFolder.id;
      selectedProject.folders = [newFolder];
    } else {
      folderId = selectedProject.folders[0].id;
    }

    const { data, error } = await supabase
      .from('notes')
      .insert({
        title,
        content: '# New Note',
        user_id: session.user.id,
        project_id: selectedProject.id,
        folder_id: folderId,
      })
      .select()
      .single();

    if (error) {
      console.error('Error creating note:', error);
      return;
    }

    projectsStore.update((currentProjects) => {
      const projectIndex = currentProjects.findIndex((p) => p.id === selectedProject.id);
      currentProjects[projectIndex].notes.push(data);
      return currentProjects;
    });
    selectedNote = data;
    noteContent = data.content;
  };

  const saveNote = async () => {
    if (!selectedNote) return;
    saveStatus = 'Saving...';

    if (isGuest) {
      projectsStore.update((currentProjects) => {
        const projectIndex = currentProjects.findIndex((p) => p.id === selectedProject.id);
        const noteIndex = currentProjects[projectIndex].notes.findIndex(
          (n) => n.id === selectedNote.id
        );
        currentProjects[projectIndex].notes[noteIndex].content = noteContent;
        return currentProjects;
      });
      setTimeout(() => (saveStatus = 'Saved'), 500);
      return;
    }

    const { data, error } = await supabase
      .from('notes')
      .update({ content: noteContent, updated_at: new Date().toISOString() })
      .eq('id', selectedNote.id);

    if (error) {
      console.error('Error saving note:', error);
      saveStatus = 'Error!';
      return;
    }
    setTimeout(() => (saveStatus = 'Saved'), 500);
  };

  const debouncedSave = () => {
    clearTimeout(saveTimeout);
    saveStatus = 'Typing...';
    saveTimeout = setTimeout(saveNote, 500);
  };

  $: if (noteContent && selectedNote) {
    debouncedSave();
  }
</script>

<main>
  <header>
    <div class="logo">MD Notes</div>
    <div>
      <span class="save-status">{saveStatus}</span>
      {#if selectedProject}
        <button on:click={createNewNote}>New Note</button>
      {/if}
      {#if session}
        <button on:click={handleLogout}>Logout</button>
      {/if}
    </div>
  </header>

  <Sidebar on:selectNote={handleSelectNote} {isGuest} />

  <section class="main-content">
    {#if selectedNote}
      <h2>{selectedNote.title}</h2>
    {/if}
    <div class="editor-container">
      <NoteEditor bind:content={noteContent} />
    </div>
    <div class="preview-container">
      <NotePreviewer content={noteContent} />
    </div>
  </section>
</main>

<style lang="scss">
  :global(body) {
    margin: 0;
    background-color: #0a0a0a;
    color: #f0f0f0;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  }

  main {
    display: flex;
    min-height: 100vh;
    background: linear-gradient(135deg, #0a0a0a 0%, #1a0a2a 100%);
  }

  header {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 15px 30px;
    background-color: rgba(0, 0, 0, 0.7);
    border-bottom: 1px solid rgba(138, 43, 226, 0.3);
    z-index: 1000;

    .logo {
      font-size: 1.5em;
      font-weight: bold;
      color: #00bfff;
      text-shadow: 0 0 8px rgba(0, 191, 255, 0.5);
    }

    .save-status {
      margin-right: 20px;
      font-style: italic;
      color: #ccc;
    }

    button {
      background: linear-gradient(45deg, #00bfff, #8a2be2);
      border: none;
      padding: 8px 15px;
      border-radius: 5px;
      color: white;
      font-size: 0.9em;
      cursor: pointer;
      transition: all 0.3s ease;
      margin-left: 10px;

      &:hover {
        opacity: 0.9;
        box-shadow: 0 0 10px rgba(0, 191, 255, 0.7);
      }
    }
  }

  .sidebar {
    width: 250px;
    background-color: #1a1a1a;
    padding: 80px 20px 20px 20px; /* Adjust padding to account for fixed header */
    border-right: 1px solid rgba(138, 43, 226, 0.3);
    box-shadow: 2px 0 10px rgba(0, 0, 0, 0.3);
    min-height: 100vh;
    box-sizing: border-box;

    h2 {
      color: #8a2be2;
      margin-bottom: 20px;
      font-size: 1.4em;
    }

    p {
      color: #ccc;
      font-size: 0.9em;
    }
  }

  .main-content {
    flex-grow: 1;
    padding: 80px 40px 20px 40px; /* Adjust padding to account for fixed header */
    box-sizing: border-box;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;

    h2 {
      grid-column: 1 / -1;
      color: #00bfff;
    }

    .editor-container,
    .preview-container {
      height: calc(100vh - 160px);
    }
  }
</style>
