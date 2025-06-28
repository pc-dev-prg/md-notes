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

  const deleteNote = async () => {
    if (!selectedNote) return;

    const confirmed = confirm('Are you sure you want to delete this note?');
    if (!confirmed) return;

    if (isGuest) {
      projectsStore.update((currentProjects) => {
        const projectIndex = currentProjects.findIndex((p) => p.id === selectedProject.id);
        currentProjects[projectIndex].notes = currentProjects[projectIndex].notes.filter(
          (n) => n.id !== selectedNote.id
        );
        return currentProjects;
      });
      selectedNote = null;
      noteContent = '';
      return;
    }

    const { error } = await supabase.from('notes').delete().eq('id', selectedNote.id);

    if (error) {
      console.error('Error deleting note:', error);
      alert('Error deleting note.');
      return;
    }

    projectsStore.update((currentProjects) => {
      const projectIndex = currentProjects.findIndex((p) => p.id === selectedProject.id);
      currentProjects[projectIndex].notes = currentProjects[projectIndex].notes.filter(
        (n) => n.id !== selectedNote.id
      );
      return currentProjects;
    });
    selectedNote = null;
    noteContent = '';
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
  <div class="background-shapes"></div>
  <Sidebar on:selectNote={handleSelectNote} {isGuest} />

  <section class="main-content">
    <header>
      <div class="header-left">
        {#if selectedNote}
          <h2>{selectedNote.title}</h2>
        {/if}
      </div>
      <div class="header-right">
        <span class="save-status">{saveStatus}</span>
        {#if selectedProject}
          <button on:click={createNewNote}>New Note</button>
        {/if}
        {#if selectedNote}
          <button on:click={deleteNote} class="delete-button">Delete</button>
        {/if}
        {#if session}
          <button on:click={handleLogout}>Logout</button>
        {/if}
      </div>
    </header>
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
    background-color: #0d0d0d;
    color: #e0e0e0;
    font-family: 'Inter', sans-serif;
  }

  main {
    position: relative;
    display: flex;
    min-height: 100vh;
    overflow: hidden;
  }

  .background-shapes {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: -1;
    background: #0d0d0d;

    &::before,
    &::after {
      content: '';
      position: absolute;
      border-radius: 50%;
      filter: blur(100px);
    }

    &::before {
      width: 300px;
      height: 300px;
      background: rgba(0, 191, 255, 0.2);
      top: -50px;
      left: 20%;
    }

    &::after {
      width: 400px;
      height: 400px;
      background: rgba(138, 43, 226, 0.2);
      bottom: -100px;
      right: 20%;
    }
  }

  .main-content {
    flex-grow: 1;
    display: grid;
    grid-template-rows: auto 1fr;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    padding: 20px;
  }

  header {
    grid-column: 1 / -1;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 15px 20px;
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;

    .header-left h2 {
      font-size: 1.5em;
      font-weight: 600;
      color: #fff;
      margin: 0;
    }

    .header-right {
      display: flex;
      align-items: center;
      gap: 20px;
    }

    .save-status {
      font-style: italic;
      color: #a0a0a0;
    }

    button {
      background: rgba(255, 255, 255, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.2);
      padding: 8px 15px;
      border-radius: 8px;
      color: white;
      font-size: 0.9em;
      cursor: pointer;
      transition: all 0.3s ease;

      &:hover {
        background: rgba(255, 255, 255, 0.2);
      }
    }

    .delete-button {
      background: rgba(255, 0, 0, 0.2);
      border-color: rgba(255, 0, 0, 0.4);

      &:hover {
        background: rgba(255, 0, 0, 0.4);
      }
    }
  }

  .editor-container,
  .preview-container {
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    height: 100%;
  }
</style>
