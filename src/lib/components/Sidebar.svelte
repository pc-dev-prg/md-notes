<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount, createEventDispatcher } from 'svelte';
  import { goto } from '$app/navigation';

  const dispatch = createEventDispatcher();

  let session = null;
  let projects = [];
  export let selectedProject = null;
  export let isGuest = false;

  onMount(async () => {
    if (isGuest) {
      projects = JSON.parse(localStorage.getItem('guest-projects')) || [];
      return;
    }

    const { data: authData, error: authError } = await supabase.auth.getSession();
    session = authData?.session;

    if (!session) {
      goto('/');
      return;
    }

    supabase.auth.onAuthStateChange((_event, newSession) => {
      session = newSession;
      if (!newSession) {
        goto('/');
      }
    });

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

    projects = projectData;
  }

  const handleLogout = async () => {
    if (isGuest) {
      localStorage.removeItem('guest-projects');
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
      projects = [newProject, ...projects];
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

    projects = [data, ...projects];
  };

  function selectNote(note) {
    dispatch('selectNote', note);
  }

  function selectProject(project) {
    selectedProject = project;
  }
</script>

<aside class="sidebar">
  <header>
    <div class="logo">MD Notes</div>
    <button on:click={handleLogout}>Logout</button>
  </header>
  <div class="projects-header">
    <h2>Projects</h2>
    <button on:click={createNewProject}>+</button>
  </div>
  {#if projects.length === 0}
    <p>No projects yet. Create one!</p>
  {:else}
    <ul>
      {#each projects as project}
        <li on:click={() => selectProject(project)}>
          <span>{project.name}</span>
          {#if selectedProject && selectedProject.id === project.id}
            <ul>
              {#each project.notes as note}
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
    width: 250px;
    background-color: #1a1a1a;
    padding: 20px;
    border-right: 1px solid rgba(138, 43, 226, 0.3);
    box-shadow: 2px 0 10px rgba(0, 0, 0, 0.3);
    min-height: 100vh;
    box-sizing: border-box;
    display: flex;
    flex-direction: column;

    header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;

      .logo {
        font-size: 1.2em;
        font-weight: bold;
        color: #00bfff;
        text-shadow: 0 0 8px rgba(0, 191, 255, 0.5);
      }

      button {
        background: linear-gradient(45deg, #00bfff, #8a2be2);
        border: none;
        padding: 5px 10px;
        border-radius: 5px;
        color: white;
        font-size: 0.8em;
        cursor: pointer;
        transition: all 0.3s ease;

        &:hover {
          opacity: 0.9;
          box-shadow: 0 0 10px rgba(0, 191, 255, 0.7);
        }
      }
    }

    .projects-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 10px;

      h2 {
        color: #8a2be2;
        font-size: 1.2em;
        margin: 0;
      }

      button {
        background: none;
        border: 1px solid #8a2be2;
        color: #8a2be2;
        width: 24px;
        height: 24px;
        border-radius: 50%;
        font-size: 1.2em;
        line-height: 20px;
        cursor: pointer;
        transition: all 0.3s ease;

        &:hover {
          background: #8a2be2;
          color: white;
        }
      }
    }

    p {
      color: #ccc;
      font-size: 0.9em;
    }

    ul {
      list-style: none;
      padding: 0;
      margin: 0;

      li {
        padding: 8px 0;
        border-bottom: 1px solid rgba(138, 43, 226, 0.1);
        color: #ddd;
        font-size: 1em;
        cursor: pointer;

        &:last-child {
          border-bottom: none;
        }

        span {
          font-weight: bold;
          color: #00bfff;
        }

        ul {
          padding-left: 15px;
          margin-top: 5px;

          li {
            font-size: 0.9em;
            padding: 5px 0;
          }
        }
      }
    }
  }
</style>
