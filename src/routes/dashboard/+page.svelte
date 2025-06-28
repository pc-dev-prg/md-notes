<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import Sidebar from '$lib/components/Sidebar.svelte';
  import NoteEditor from '$lib/components/NoteEditor.svelte';
  import NotePreviewer from '$lib/components/NotePreviewer.svelte';
  import { sessionStore, projectsStore, selectedProjectStore, themeStore } from '$lib/store';

  let session;
  sessionStore.subscribe((value) => {
    session = value;
  });

  let selectedProject;
  selectedProjectStore.subscribe((value) => {
    selectedProject = value;
  });

  let theme;
  themeStore.subscribe((value) => {
    theme = value;
  });

  let noteContent = '# Hello, Markdown!';
  let selectedNote = null;
  let isGuest = false;
  let saveTimeout;
  let saveStatus = 'Saved';
  let sidebarOpen = true;

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

    let folderId = null;
    if (selectedProject.folders.length > 0) {
      const folderNames = selectedProject.folders.map((f) => f.name);
      const selectedFolder = prompt(
        `Select a folder (optional):\n${folderNames.join('\n')}`
      );
      if (selectedFolder) {
        const folder = selectedProject.folders.find((f) => f.name === selectedFolder);
        if (folder) {
          folderId = folder.id;
        } else {
          alert('Invalid folder name.');
          return;
        }
      }
    }

    if (isGuest) {
      const newNote = {
        id: Math.random().toString(36).substring(2),
        title,
        content: '# New Note',
        project_id: selectedProject.id,
        folder_id: folderId,
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

<main class:sidebar-closed={!sidebarOpen} class={theme}>
  <div class="background-shapes"></div>
  <Sidebar on:selectNote={handleSelectNote} {isGuest} />

  <section class="main-content">
    <header>
      <div class="header-left">
        <button class="hamburger" on:click={() => (sidebarOpen = !sidebarOpen)}>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <line x1="3" y1="12" x2="21" y2="12" />
            <line x1="3" y1="6" x2="21" y2="6" />
            <line x1="3" y1="18" x2="21" y2="18" />
          </svg>
        </button>
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
  :root {
    --bg-color: #0d0d0d;
    --text-color: #e0e0e0;
    --sidebar-bg: rgba(255, 255, 255, 0.05);
    --border-color: rgba(255, 255, 255, 0.1);
    --button-bg: rgba(255, 255, 255, 0.1);
    --button-hover-bg: rgba(255, 255, 255, 0.2);
    --input-bg: rgba(255, 255, 255, 0.1);
    --placeholder-color: #a0a0a0;
    --selected-bg: rgba(0, 191, 255, 0.2);
    --hover-bg: rgba(255, 255, 255, 0.1);
    --accent-color: #00bfff;
  }

  .light {
    --bg-color: #f5f5f5;
    --text-color: #333;
    --sidebar-bg: rgba(0, 0, 0, 0.05);
    --border-color: rgba(0, 0, 0, 0.1);
    --button-bg: rgba(0, 0, 0, 0.1);
    --button-hover-bg: rgba(0, 0, 0, 0.2);
    --input-bg: rgba(0, 0, 0, 0.1);
    --placeholder-color: #666;
    --selected-bg: rgba(0, 191, 255, 0.2);
    --hover-bg: rgba(0, 0, 0, 0.1);
  }

  :global(body) {
    margin: 0;
    background-color: var(--bg-color);
    color: var(--text-color);
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
    background: var(--bg-color);

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
    transition: margin-left 0.3s ease;
  }

  header {
    grid-column: 1 / -1;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 15px 20px;
    background: var(--sidebar-bg);
    backdrop-filter: blur(10px);
    border: 1px solid var(--border-color);
    border-radius: 12px;

    .header-left {
      display: flex;
      align-items: center;
      gap: 15px;
    }

    .hamburger {
      display: none;
      background: none;
      border: none;
      color: var(--text-color);
      cursor: pointer;
    }

    .header-left h2 {
      font-size: 1.5em;
      font-weight: 600;
      color: var(--text-color);
      margin: 0;
    }

    .header-right {
      display: flex;
      align-items: center;
      gap: 20px;
    }

    .save-status {
      font-style: italic;
      color: var(--placeholder-color);
    }

    button {
      background: var(--button-bg);
      border: 1px solid var(--border-color);
      padding: 8px 15px;
      border-radius: 8px;
      color: var(--text-color);
      font-size: 0.9em;
      cursor: pointer;
      transition: all 0.3s ease;

      &:hover {
        background: var(--button-hover-bg);
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
    background: var(--sidebar-bg);
    backdrop-filter: blur(10px);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    height: 100%;
  }

  @media (max-width: 768px) {
    .sidebar {
      position: fixed;
      left: -280px;
      top: 0;
      height: 100%;
      z-index: 100;
      transition: left 0.3s ease;
    }

    main:not(.sidebar-closed) .sidebar {
      left: 0;
    }

    .main-content {
      margin-left: 0;
      grid-template-columns: 1fr;
    }

    header .hamburger {
      display: block;
    }
  }
</style>
