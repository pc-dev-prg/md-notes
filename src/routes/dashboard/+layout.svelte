<script>
  import Sidebar from '$lib/components/Sidebar.svelte';
  import { sessionStore, themeStore } from '$lib/store';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';

  let session;
  sessionStore.subscribe((value) => {
    session = value;
  });

  let theme;
  themeStore.subscribe((value) => {
    theme = value;
  });

  let isGuest = false;
  let sidebarOpen = true;

  onMount(() => {
    const guestSession = JSON.parse(localStorage.getItem('session'));
    if (guestSession && guestSession.user.id === 'guest') {
      isGuest = true;
      sessionStore.set(guestSession);
    } else if (session?.user?.id === 'guest') {
      isGuest = true;
    } else if (!session) {
      goto('/');
    }
  });
</script>

<main class:sidebar-closed={!sidebarOpen} class={theme}>
  <div class="background-shapes"></div>
  <Sidebar {isGuest} on:toggleSidebar={() => (sidebarOpen = !sidebarOpen)} />
  <slot />
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
</style>
