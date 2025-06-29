<script>
  import { createEventDispatcher } from 'svelte';
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { selectedProjectStore } from '$lib/store';
  import { dndzone } from 'svelte-dnd-action';
  import { supabase } from '$lib/supabaseClient';
  import { sessionStore } from '$lib/store';

  const dispatch = createEventDispatcher();

  let selectedProject;
  selectedProjectStore.subscribe((value) => {
    selectedProject = value;
  });

  export let isGuest = false;
  let searchTerm = '';

  $: filteredNotes = selectedProject ? selectedProject.notes.filter((note) =>
    note.title.toLowerCase().includes(searchTerm.toLowerCase())
  ) : [];

  $: filteredFolders = selectedProject ? selectedProject.folders.filter((folder) =>
    folder.name.toLowerCase().includes(searchTerm.toLowerCase())
  ) : [];

  const createNewFolder = async () => {
    if (!selectedProject) return;
    const name = prompt('Enter folder name:');
    if (!name) return;

    if (isGuest) {
      const newFolder = {
        id: Math.random().toString(36).substring(2),
        name,
        project_id: selectedProject.id,
        notes: [],
      };
      selectedProject.folders = [...selectedProject.folders, newFolder];
      return;
    }

    const { data, error } = await supabase
      .from('folders')
      .insert({ name, project_id: selectedProject.id, user_id: session.user.id })
      .select()
      .single();

    if (error) {
      console.error('Error creating folder:', error);
      return;
    }

    selectedProject.folders = [...selectedProject.folders, data];
  };

  const createNewNote = async (folderId = null) => {
    if (!selectedProject) return;
    const title = prompt('Enter note title:');
    if (!title) return;

    if (isGuest) {
      const newNote = {
        id: Math.random().toString(36).substring(2),
        title,
        content: '# New Note',
        project_id: selectedProject.id,
        folder_id: folderId,
      };
      selectedProject.notes = [...selectedProject.notes, newNote];
      goto(`/dashboard/${newNote.id}`);
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

    selectedProject.notes = [...selectedProject.notes, data];
    goto(`/dashboard/${data.id}`);
  };

  const handleDnd = (e, list) => {
    const { items, source, trigger } = e.detail;
    list = items;

    if (trigger === 'dropped') {
      const updates = list.map((item, index) => {
        return {
          id: item.id,
          order: index,
        };
      });

      if (isGuest) {
        selectedProject.notes = list;
      } else {
        const tableName = list[0].folder_id ? 'notes' : 'folders';
        supabase.from(tableName).upsert(updates).then();
      }
    }
  };
</script>

<aside class="sidebar">
  {#if selectedProject}
    <div class="project-header">
      <h2>{selectedProject.name}</h2>
      <div class="header-buttons">
        <button on:click={() => createNewFolder()} aria-label="Create new folder">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path></svg>
        </button>
        <button on:click={() => createNewNote()} aria-label="Create new note">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="12" y1="18" x2="12" y2="12"></line><line x1="9" y1="15" x2="15" y2="15"></line></svg>
        </button>
      </div>
    </div>
    <div class="search-bar">
      <input type="text" placeholder="Search notes..." bind:value={searchTerm} />
    </div>
    <ul class="tree-view" use:dndzone={{ items: [...filteredFolders, ...filteredNotes] }} on:consider={(e) => handleDnd(e, [...filteredFolders, ...filteredNotes])} on:finalize={(e) => handleDnd(e, [...filteredFolders, ...filteredNotes])}>
      {#each filteredFolders as folder (folder.id)}
        <li class="folder">
          <div class="item-content">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path></svg>
            <span>{folder.name}</span>
            <button class="add-note-to-folder" on:click|stopPropagation={() => createNewNote(folder.id)}>+</button>
          </div>
          <ul use:dndzone={{ items: filteredNotes.filter(n => n.folder_id === folder.id) }} on:consider={(e) => handleDnd(e, filteredNotes)} on:finalize={(e) => handleDnd(e, filteredNotes)}>
            {#each filteredNotes.filter(n => n.folder_id === folder.id) as note (note.id)}
              <li class="note" on:click={() => goto(`/dashboard/${note.id}`)} class:selected={$page.params.noteId === note.id}>
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
                <span>{note.title}</span>
              </li>
            {/each}
          </ul>
        </li>
      {/each}
      {#each filteredNotes.filter(n => !n.folder_id) as note (note.id)}
        <li class="note" on:click={() => goto(`/dashboard/${note.id}`)} class:selected={$page.params.noteId === note.id}>
          <div class="item-content">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline></svg>
            <span>{note.title}</span>
          </div>
        </li>
      {/each}
    </ul>
  {:else}
    <p>Select a project to see your notes.</p>
  {/if}
</aside>

<style lang="scss">
  .sidebar {
    width: 280px;
    background: var(--sidebar-bg);
    backdrop-filter: blur(10px);
    border-right: 1px solid var(--border-color);
    padding: 20px;
    display: flex;
    flex-direction: column;
    gap: 20px;
  }

  .project-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;

    h2 {
      font-size: 1.5em;
      font-weight: 600;
      color: var(--text-color);
      margin: 0;
    }

    .header-buttons {
      display: flex;
      gap: 10px;
    }

    button {
      background: var(--button-bg);
      border: 1px solid var(--border-color);
      color: var(--text-color);
      width: 30px;
      height: 30px;
      border-radius: 8px;
      font-size: 1.5em;
      line-height: 1;
      cursor: pointer;
      transition: all 0.3s ease;
      display: flex;
      justify-content: center;
      align-items: center;

      &:hover {
        background: var(--button-hover-bg);
      }
    }
  }

  .search-bar input {
    width: 100%;
    padding: 10px 15px;
    border-radius: 8px;
    border: 1px solid var(--border-color);
    background: var(--input-bg);
    color: var(--text-color);
    font-size: 1em;
    box-sizing: border-box;

    &::placeholder {
      color: var(--placeholder-color);
    }

    &:focus {
      outline: none;
      border-color: var(--accent-color);
    }
  }

  p {
    color: var(--placeholder-color);
    text-align: center;
    margin-top: 20px;
  }

  .tree-view {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 5px;
    margin-top: 10px;

    .folder, .note {
      padding: 8px 12px;
      border-radius: 8px;
      color: var(--placeholder-color);
      cursor: pointer;
      transition: all 0.3s ease;

      &.selected {
        background: var(--selected-bg);
        color: var(--text-color);
      }

      &:hover {
        background: var(--hover-bg);
      }

      .item-content {
        display: flex;
        align-items: center;
        gap: 10px;
      }

      svg {
        flex-shrink: 0;
      }

      .add-note-to-folder {
        margin-left: auto;
        opacity: 0;
        transition: opacity 0.2s ease;
        background: none;
        border: none;
        color: var(--text-color);
        font-size: 1.2em;
        padding: 0 5px;
      }

      &:hover .add-note-to-folder {
        opacity: 1;
      }
    }

    ul {
      padding-left: 20px;
      margin-top: 5px;
      list-style: none;
    }
  }
</style>




