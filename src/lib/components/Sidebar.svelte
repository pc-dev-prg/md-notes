<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount, createEventDispatcher } from 'svelte';
  import { goto } from '$app/navigation';
  import { sessionStore, projectsStore, selectedProjectStore } from '$lib/store';

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

  export let isGuest = false;

  onMount(async () => {
    if (isGuest) {
      projectsStore.set(JSON.parse(localStorage.getItem('guest-projects')) || []);
      return;
    }

    if (!session) {
      goto('/');
      return;
    }

    await fetchProjects();
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
</script>

<aside class="sidebar">
  <div class="logo">MD Notes</div>
  <div class="projects-header">
    <h2>Projects</h2>
    <button on:click={createNewProject}>+</button>
  </div>
  {#if projects.length === 0}
    <p>No projects yet. Create one!</p>
  {:else}
    <ul>
      {#each projects as project}
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
            <ul>
              {#each project.folders as folder}
                <li>
                  <span>{folder.name}</span>
                  <ul>
                    {#each project.notes.filter((n) => n.folder_id === folder.id) as note}
                      <li on:click|stopPropagation={() => selectNote(note)}>{note.title}</li>
                    {/each}
                  </ul>
                </li>
              {/each}
            </ul>
            <h3>Notes</h3>
            <ul>
              {#each project.notes.filter((n) => !n.folder_id) as note}
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
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(10px);
    border-right: 1px solid rgba(255, 255, 255, 0.1);
    padding: 20px;
    display: flex;
    flex-direction: column;
    gap: 20px;

    .logo {
      font-size: 1.8em;
      font-weight: 700;
      color: #fff;
      text-align: center;
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
        color: #fff;
        margin: 0;
      }

      button {
        background: rgba(255, 255, 255, 0.1);
        border: 1px solid rgba(255, 255, 255, 0.2);
        color: #fff;
        width: 30px;
        height: 30px;
        border-radius: 8px;
        font-size: 1.5em;
        line-height: 28px;
        cursor: pointer;
        transition: all 0.3s ease;

        &:hover {
          background: rgba(255, 255, 255, 0.2);
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
      color: #a0a0a0;
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
        color: #a0a0a0;
        cursor: pointer;
        transition: all 0.3s ease;

        &.selected {
          background: rgba(0, 191, 255, 0.2);
          color: #fff;
        }

        &:hover {
          background: rgba(255, 255, 255, 0.1);
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
