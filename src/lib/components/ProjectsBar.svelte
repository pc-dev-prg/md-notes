<script>
  import { onMount } from 'svelte';
  import { projectsStore, selectedProjectStore } from '$lib/store';
  import { supabase } from '$lib/supabaseClient';
  import { sessionStore } from '$lib/store';

  let projects = [];
  let selectedProject = null;
  let session;

  projectsStore.subscribe(value => projects = value);
  selectedProjectStore.subscribe(value => selectedProject = value);
  sessionStore.subscribe(value => session = value);

  const createNewProject = async () => {
    const name = prompt('Enter project name:');
    if (!name) return;

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

  function selectProject(project) {
    selectedProjectStore.set(project);
  }
</script>

<aside class="projects-bar">
  <div class="projects-list">
    {#each projects as project (project.id)}
      <button
        class="project-icon"
        class:selected={selectedProject && selectedProject.id === project.id}
        on:click={() => selectProject(project)}
        aria-label={project.name}
      >
        {project.name.charAt(0).toUpperCase()}
      </button>
    {/each}
  </div>
  <button class="new-project-button" on:click={createNewProject} aria-label="Create new project">+</button>
</aside>

<style lang="scss">
  .projects-bar {
    width: 60px;
    background: #000;
    padding: 20px 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 20px;
    border-right: 1px solid var(--border-color);
  }

  .projects-list {
    display: flex;
    flex-direction: column;
    gap: 15px;
  }

  .project-icon {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: var(--button-bg);
    color: var(--text-color);
    display: flex;
    justify-content: center;
    align-items: center;
    font-size: 1.2em;
    font-weight: 600;
    cursor: pointer;
    border: 2px solid transparent;
    transition: all 0.3s ease;

    &.selected {
      border-color: var(--accent-color);
    }

    &:hover {
      background: var(--button-hover-bg);
    }
  }

  .new-project-button {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: var(--button-bg);
    color: var(--text-color);
    display: flex;
    justify-content: center;
    align-items: center;
    font-size: 1.5em;
    cursor: pointer;
    border: none;
    margin-top: auto;

    &:hover {
      background: var(--button-hover-bg);
    }
  }
</style>
