<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount, createEventDispatcher } from 'svelte';
  import { goto } from '$app/navigation';
  import { sessionStore, projectsStore, selectedProjectStore, themeStore } from '$lib/store';
  import { dndzone } from 'svelte-dnd-action';
  import { openDB, getStore } from '$lib/local-db';

  const dispatch = createEventDispatcher();

  let session;
  sessionStore.subscribe((value) => {
    session = value;
  });

  let projects;
  projectsStore.subscribe((value) => {
    projects = value;
  });

  let selectedProject;
  selectedProjectStore.subscribe((value) => {
    selectedProject = value;
  });

  let theme;
  themeStore.subscribe((value) => {
    theme = value;
  });

  export let isGuest = false;
  let searchTerm = '';
  let avatarUrl = null;
  let online = navigator.onLine;

  window.addEventListener('online', () => (online = true));
  window.addEventListener('offline', () => (online = false));

  $: filteredProjects = projects.filter((project) => {
    const term = searchTerm.toLowerCase();
    const hasMatchingNote = project.notes.some((note) =>
      note.title.toLowerCase().includes(term)
    );
    const hasMatchingFolder = project.folders.some((folder) =>
      folder.name.toLowerCase().includes(term)
    );
    return (
      project.name.toLowerCase().includes(term) || hasMatchingNote || hasMatchingFolder
    );
  });

  onMount(async () => {
    if (isGuest) {
      projectsStore.set(JSON.parse(localStorage.getItem('guest-projects')) || []);
      return;
    }

    if (!session) {
      goto('/');
      return;
    }

    if (online) {
      await fetchProjects();
      await fetchProfile();
    } else {
      const db = await openDB();
      const projectsStore = getStore('projects', 'readonly');
      const request = projectsStore.getAll();
      request.onsuccess = (event) => {
        projectsStore.set(event.target.result);
      };
    }
  });

  async function fetchProjects() {
    const { data: projectData, error: projectError } = await supabase
      .from('projects')
      .select('*, notes(*), folders(*)')
      .eq('user_id', session.user.id)
      .order('created_at', { ascending: false });

    if (projectError) {
      console.error('Error fetching projects:', projectError);
      return;
    }

    projectsStore.set(projectData);
    const db = await openDB();
    const projectsTx = db.transaction('projects', 'readwrite');
    projectData.forEach((project) => {
      projectsTx.objectStore('projects').put(project);
    });
  }

  async function fetchProfile() {
    const { data, error } = await supabase
      .from('profiles')
      .select('avatar_url')
      .eq('id', session.user.id)
      .single();

    if (error) {
      console.error('Error fetching profile:', error);
    } else {
      avatarUrl = data.avatar_url;
    }
  }

  const handleLogout = async () => {
    if (isGuest) {
      localStorage.removeItem('guest-projects');
      sessionStore.set(null);
      goto('/');
      return;
    }
    const { error } = await supabase.auth.signOut();
    if (error) alert(error.message);
  };

  const createNewProject = async () => {
    const name = prompt('Enter project name:');
    if (!name) return;

    if (isGuest) {
      const newProject = {
        id: Math.random().toString(36).substring(2),
        name,
        notes: [],
        folders: [],
      };
      projectsStore.update((currentProjects) => [newProject, ...currentProjects]);
      localStorage.setItem('guest-projects', JSON.stringify(projects));
      return;
    }

    const { data, error } = await supabase
      .from('projects')
      .insert({ name, user_id: session.user.id })
      .select('*, notes(*), folders(*)')
      .single();

    if (error) {
      console.error('Error creating project:', error);
      return;
    }

    projectsStore.update((currentProjects) => [data, ...currentProjects]);
  };

  const createNewFolder = async () => {
    if (!selectedProject) {
      alert('Please select a project first.');
      return;
    }

    const name = prompt('Enter folder name:');
    if (!name) return;

    if (isGuest) {
      const newFolder = {
        id: Math.random().toString(36).substring(2),
        name,
        project_id: selectedProject.id,
      };
      projectsStore.update((currentProjects) => {
        const projectIndex = currentProjects.findIndex((p) => p.id === selectedProject.id);
        currentProjects[projectIndex].folders.push(newFolder);
        return currentProjects;
      });
      localStorage.setItem('guest-projects', JSON.stringify(projects));
      return;
    }

    const { data, error } = await supabase
      .from('folders')
      .insert({ name, project_id: selectedProject.id })
      .select()
      .single();

    if (error) {
      console.error('Error creating folder:', error);
      return;
    }

    projectsStore.update((currentProjects) => {
      const projectIndex = currentProjects.findIndex((p) => p.id === selectedProject.id);
      currentProjects[projectIndex].folders.push(data);
      return currentProjects;
    });
  };

  function selectNote(note) {
    dispatch('selectNote', note);
  }

  function selectProject(project) {
    selectedProjectStore.set(project);
  }

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
        projectsStore.update((currentProjects) => {
          const projectIndex = currentProjects.findIndex((p) => p.id === selectedProject.id);
          if (list[0].folder_id) {
            currentProjects[projectIndex].notes = list;
          } else {
            currentProjects[projectIndex].folders = list;
          }
          return currentProjects;
        });
        localStorage.setItem('guest-projects', JSON.stringify(projects));
      } else {
        const tableName = list[0].folder_id ? 'notes' : 'folders';
        supabase.from(tableName).upsert(updates).then();
      }
    }
  };

  const toggleTheme = () => {
    themeStore.update((currentTheme) => (currentTheme === 'dark' ? 'light' : 'dark'));
  };
</script>

<aside class="sidebar">
  <div class="profile-section">
    <a href="/profile" class="avatar-link">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="40"
        height="40"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        class="avatar"
      >
        <path d="M12 22s-8-4.5-8-11.8A8 8 0 0 1 12 2a8 8 0 0 1 8 9.8c0 7.3-8 11.8-8 11.8z" />
        <circle cx="12" cy="10" r="3" />
      </svg>
    </a>
    <div class="logo">MD Notes</div>
    <button on:click={handleLogout}>Logout</button>
  </div>
  <div class="status-bar">
    <div class="theme-toggle">
      <span>{theme === 'dark' ? 'Dark' : 'Light'} Mode</span>
      <button on:click={toggleTheme}>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="20"
          height="20"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          {#if theme === 'dark'}
            <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
          {:else}
            <circle cx="12" cy="12" r="5" />
            <line x1="12" y1="1" x2="12" y2="3" />
            <line x1="12" y1="21" x2="12" y2="23" />
            <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" />
            <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" />
            <line x1="1" y1="12" x2="3" y2="12" />
            <line x1="21" y1="12" x2="23" y2="12" />
            <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" />
            <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" />
          {/if}
        </svg>
      </button>
    </div>
    <div class="offline-indicator" class:offline={!online}>
      {online ? 'Online' : 'Offline'}
    </div>
  </div>
  <div class="search-bar">
    <input type="text" placeholder="Search..." bind:value={searchTerm} />
  </div>
  <div class="projects-header">
    <h2>Projects</h2>
    <button on:click={createNewProject}>+</button>
  </div>
  {#if filteredProjects.length === 0}
    <p>No projects yet. Create one!</p>
  {:else}
    <ul use:dndzone={{ items: filteredProjects }} on:consider={(e) => handleDnd(e, filteredProjects)} on:finalize={(e) => handleDnd(e, filteredProjects)}>
      {#each filteredProjects as project (project.id)}
        <li
          class:selected={selectedProject && selectedProject.id === project.id}
          on:click={() => selectProject(project)}
        >
          <span>{project.name}</span>
          {#if selectedProject && selectedProject.id === project.id}
            <div class="folder-header">
              <h3>Folders</h3>
              <button on:click|stopPropagation={createNewFolder}>+</button>
            </div>
            <ul use:dndzone={{ items: project.folders }} on:consider={(e) => handleDnd(e, project.folders)} on:finalize={(e) => handleDnd(e, project.folders)}>
              {#each project.folders as folder (folder.id)}
                <li>
                  <span>{folder.name}</span>
                  <ul use:dndzone={{ items: project.notes.filter((n) => n.folder_id === folder.id) }} on:consider={(e) => handleDnd(e, project.notes)} on:finalize={(e) => handleDnd(e, project.notes)}>
                    {#each project.notes.filter((n) => n.folder_id === folder.id) as note (note.id)}
                      <li on:click|stopPropagation={() => selectNote(note)}>{note.title}</li>
                    {/each}
                  </ul>
                </li>
              {/each}
            </ul>
            <h3>Notes</h3>
            <ul use:dndzone={{ items: project.notes.filter((n) => !n.folder_id) }} on:consider={(e) => handleDnd(e, project.notes)} on:finalize={(e) => handleDnd(e, project.notes)}>
              {#each project.notes.filter((n) => !n.folder_id) as note (note.id)}
                <li on:click|stopPropagation={() => selectNote(note)}>{note.title}</li>
              {/each}
            </ul>
          {/if}
        </li>
      {/each}
    </ul>
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

    .profile-section {
      display: flex;
      align-items: center;
      gap: 15px;

      .avatar {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        object-fit: cover;
      }

      .logo {
        font-size: 1.5em;
        font-weight: 500;
        color: var(--text-color);
      }

      button {
        margin-left: auto;
        background: var(--button-bg);
        border: 1px solid var(--border-color);
        color: var(--text-color);
        padding: 8px 12px;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.3s ease;

        &:hover {
          background: var(--button-hover-bg);
        }
      }
    }

    .status-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 12px;
      background: var(--button-bg);
      border-radius: 8px;
    }

    .theme-toggle {
      display: flex;
      align-items: center;
      gap: 10px;

      span {
        color: var(--text-color);
      }

      button {
        background: none;
        border: none;
        color: var(--text-color);
        cursor: pointer;
      }
    }

    .offline-indicator {
      font-style: italic;
      color: var(--placeholder-color);

      &.offline {
        color: #ff6b6b;
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

    .projects-header,
    .folder-header {
      display: flex;
      justify-content: space-between;
      align-items: center;

      h2,
      h3 {
        font-size: 1.2em;
        font-weight: 600;
        color: var(--text-color);
        margin: 0;
      }

      button {
        background: var(--button-bg);
        border: 1px solid var(--border-color);
        color: var(--text-color);
        width: 30px;
        height: 30px;
        border-radius: 8px;
        font-size: 1.5em;
        line-height: 28px;
        cursor: pointer;
        transition: all 0.3s ease;

        &:hover {
          background: var(--button-hover-bg);
        }
      }
    }

    .folder-header {
      margin-top: 15px;
      h3 {
        font-size: 1.1em;
      }
    }

    p {
      color: var(--placeholder-color);
      text-align: center;
    }

    ul {
      list-style: none;
      padding: 0;
      margin: 0;
      display: flex;
      flex-direction: column;
      gap: 5px;

      li {
        padding: 10px 15px;
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

        span {
          font-weight: 600;
        }

        ul {
          padding-left: 15px;
          margin-top: 10px;
          display: flex;
          flex-direction: column;
          gap: 5px;

          li {
            font-size: 0.9em;
            padding: 8px 10px;
          }
        }
      }
    }
  }
</style>
