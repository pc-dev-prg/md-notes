<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount, onDestroy } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import NoteEditor from '$lib/components/NoteEditor.svelte';
  import NotePreviewer from '$lib/components/NotePreviewer.svelte';
  import Notifications from '$lib/components/Notifications.svelte';
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

  let noteContent = '';
  let selectedNote = null;
  let isGuest = false;
  let saveTimeout;
  let saveStatus = 'Saved';
  let showShareModal = false;
  let showHistoryModal = false;
  let collaboratorEmail = '';
  let permissionLevel = 'view';
  let channel;
  let noteHistory = [];

  onMount(async () => {
    const guestSession = JSON.parse(localStorage.getItem('session'));
    if (guestSession && guestSession.user.id === 'guest') {
      isGuest = true;
      sessionStore.set(guestSession);
    } else if (session?.user?.id === 'guest') {
      isGuest = true;
    } else if (!session) {
      goto('/');
    }

    const noteId = $page.params.noteId;
    
    if (noteId) {
      if (isGuest) {
        const guestProjects = JSON.parse(localStorage.getItem('guest-projects')) || [];
        const note = guestProjects.flatMap(p => p.notes).find(n => n.id === noteId);
        if (note) {
          selectedNote = note;
          noteContent = note.content;
        } else {
          goto('/dashboard');
        }
        return;
      }

      const { data, error } = await supabase
        .from('notes')
        .select('*')
        .eq('id', noteId)
        .single();

      if (error) {
        console.error('Error fetching note:', error);
        goto('/dashboard');
      } else {
        selectedNote = data;
        noteContent = data.content;

        if (selectedNote && !isGuest) {
          channel = supabase.channel(`note:${selectedNote.id}`);
          channel
            .on('broadcast', { event: 'update' }, (payload) => {
              if (payload.author !== session.user.id) {
                noteContent = payload.content;
              }
            })
            .subscribe();
        }
      }
    }
  });

  onDestroy(() => {
    if (channel) {
      supabase.removeChannel(channel);
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

    if (channel) {
      channel.send({
        type: 'broadcast',
        event: 'update',
        payload: {
          author: session.user.id,
          content: noteContent,
        },
      });
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
      goto('/dashboard');
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
    goto('/dashboard');
  };

  const debouncedSave = () => {
    clearTimeout(saveTimeout);
    saveStatus = 'Typing...';
    saveTimeout = setTimeout(saveNote, 500);
  };

  const inviteCollaborator = async () => {
    if (!collaboratorEmail) {
      alert('Please enter an email address.');
      return;
    }

    const { data: user, error: userError } = await supabase
      .from('profiles')
      .select('id')
      .eq('username', collaboratorEmail)
      .single();

    if (userError || !user) {
      alert('User not found.');
      return;
    }

    const { error } = await supabase.from('note_collaborators').insert({
      note_id: selectedNote.id,
      user_id: user.id,
      permission_level: permissionLevel,
    });

    if (error) {
      console.error('Error inviting collaborator:', error);
      alert('Error inviting collaborator.');
    } else {
      const { error: notificationError } = await supabase.from('notifications').insert({
        user_id: user.id,
        sender_id: session.user.id,
        note_id: selectedNote.id,
        type: 'new_collaborator',
      });

      if (notificationError) {
        console.error('Error creating notification:', notificationError);
      }

      alert('Collaborator invited successfully.');
      showShareModal = false;
    }
  };

  const togglePublic = async () => {
    if (!selectedNote) return;

    const { data, error } = await supabase
      .from('notes')
      .update({ is_public: !selectedNote.is_public })
      .eq('id', selectedNote.id)
      .select()
      .single();

    if (error) {
      console.error('Error updating note:', error);
      alert('Error updating note.');
    } else {
      selectedNote = data;
    }
  };

  const exportNote = async () => {
    if (!selectedNote) return;
    const { saveAs } = await import('file-saver');
    const blob = new Blob([noteContent], { type: 'text/markdown;charset=utf-8' });
    saveAs(blob, `${selectedNote.title}.md`);
  };

  const fetchHistory = async () => {
    if (!selectedNote) return;
    const { data, error } = await supabase
      .from('note_history')
      .select('*')
      .eq('note_id', selectedNote.id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching history:', error);
    }
    else {
      noteHistory = data;
      showHistoryModal = true;
    }
  };

  const restoreVersion = (historyItem) => {
    noteContent = historyItem.content;
    showHistoryModal = false;
  };

  $: if (noteContent && selectedNote) {
    debouncedSave();
  }
</script>

<section class="main-content">
    <header>
      <div class="header-left">
        <button class="hamburger" on:click={() => dispatch('toggleSidebar')} aria-label="Toggle sidebar">
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
        <Notifications />
        <span class="save-status">{saveStatus}</span>
        {#if selectedNote}
          <button on:click={fetchHistory}>History</button>
          <button on:click={exportNote}>Export</button>
          <div class="public-toggle">
            <span>Share Publicly</span>
            <label class="switch">
              <input type="checkbox" bind:checked={selectedNote.is_public} on:change={togglePublic} />
              <span class="slider"></span>
            </label>
          </div>
          {#if selectedNote.is_public}
            <input
              type="text"
              readonly
              value={`${window.location.origin}/public/${selectedNote.public_id}`}
            />
          {/if}
          <button on:click={() => (showShareModal = true)}>Share</button>
        {/if}
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

  {#if showShareModal}
    <div class="modal-overlay" on:click={() => (showShareModal = false)} on:keydown={() => {}} role="button" tabindex="0">
      <div class="modal" on:click|stopPropagation on:keydown={() => {}} role="button" tabindex="0">
        <h2>Invite Collaborator</h2>
        <form on:submit|preventDefault={inviteCollaborator}>
          <input type="email" placeholder="Enter email" bind:value={collaboratorEmail} />
          <select bind:value={permissionLevel}>
            <option value="view">Can view</option>
            <option value="edit">Can edit</option>
          </select>
          <button type="submit">Invite</button>
        </form>
      </div>
    </div>
  {/if}

  {#if showHistoryModal}
    <div class="modal-overlay" on:click={() => (showHistoryModal = false)} on:keydown={() => {}} role="button" tabindex="0">
      <div class="modal" on:click|stopPropagation on:keydown={() => {}} role="button" tabindex="0">
        <h2>Version History</h2>
        <ul>
          {#each noteHistory as item}
            <li>
              <p>
                <strong>{new Date(item.created_at).toLocaleString()}</strong>
              </p>
              <button on:click={() => restoreVersion(item)}>Restore</button>
            </li>
          {/each}
        </ul>
      </div>
    </div>
  {/if}

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

    .public-toggle {
      display: flex;
      align-items: center;
      gap: 10px;

      .switch {
        position: relative;
        display: inline-block;
        width: 40px;
        height: 20px;

        input {
          opacity: 0;
          width: 0;
          height: 0;
        }

        .slider {
          position: absolute;
          cursor: pointer;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background-color: #ccc;
          transition: 0.4s;
          border-radius: 20px;

          &:before {
            position: absolute;
            content: '';
            height: 16px;
            width: 16px;
            left: 2px;
            bottom: 2px;
            background-color: white;
            transition: 0.4s;
            border-radius: 50%;
          }
        }

        input:checked + .slider {
          background-color: var(--accent-color);
        }

        input:checked + .slider:before {
          transform: translateX(20px);
        }
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

  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
  }

  .modal {
    background: var(--sidebar-bg);
    backdrop-filter: blur(10px);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 30px;
    width: 100%;
    max-width: 400px;

    h2 {
      margin-top: 0;
    }

    form {
      display: flex;
      flex-direction: column;
      gap: 15px;

      input,
      select {
        width: 100%;
        padding: 10px 15px;
        border-radius: 8px;
        border: 1px solid var(--border-color);
        background: var(--input-bg);
        color: var(--text-color);
        font-size: 1em;
        box-sizing: border-box;
      }

      button {
        background: var(--accent-color);
        border: none;
        padding: 10px 15px;
        border-radius: 8px;
        color: #fff;
        font-size: 1em;
        cursor: pointer;
      }
    }

    ul {
      list-style: none;
      padding: 0;
      margin: 0;
      display: flex;
      flex-direction: column;
      gap: 10px;

      li {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 10px;
        border-radius: 8px;
        background: var(--hover-bg);

        p {
          margin: 0;
        }

        button {
          background: var(--accent-color);
          border: none;
          padding: 5px 10px;
          border-radius: 8px;
          color: #fff;
          cursor: pointer;
        }
      }
    }
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

    

    .main-content {
      margin-left: 0;
      grid-template-columns: 1fr;
    }

    header .hamburger {
      display: block;
    }
  }
</style>


