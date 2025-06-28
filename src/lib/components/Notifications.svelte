<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';
  import { sessionStore } from '$lib/store';

  let session;
  sessionStore.subscribe((value) => {
    session = value;
  });

  let notifications = [];
  let unreadCount = 0;
  let showNotifications = false;

  onMount(async () => {
    if (session) {
      await fetchNotifications();

      const channel = supabase.channel(`notifications:${session.user.id}`);
      channel
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications' }, () => {
          fetchNotifications();
        })
        .subscribe();
    }
  });

  async function fetchNotifications() {
    const { data, error } = await supabase
      .from('notifications')
      .select('*, sender:sender_id(username)')
      .eq('user_id', session.user.id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching notifications:', error);
    } else {
      notifications = data;
      unreadCount = data.filter((n) => !n.is_read).length;
    }
  }

  async function markAsRead(notificationId) {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', notificationId);

    if (error) {
      console.error('Error marking notification as read:', error);
    } else {
      fetchNotifications();
    }
  }
</script>

<div class="notifications-container">
  <button class="notifications-toggle" on:click={() => (showNotifications = !showNotifications)}>
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
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
    {#if unreadCount > 0}
      <span class="badge">{unreadCount}</span>
    {/if}
  </button>

  {#if showNotifications}
    <div class="notifications-dropdown">
      {#if notifications.length === 0}
        <p>No notifications</p>
      {:else}
        <ul>
          {#each notifications as notification}
            <li class:unread={!notification.is_read} on:click={() => markAsRead(notification.id)}>
              <p>
                <strong>{notification.sender.username}</strong>
                invited you to collaborate on a note.
              </p>
              <span>{new Date(notification.created_at).toLocaleString()}</span>
            </li>
          {/each}
        </ul>
      {/if}
    </div>
  {/if}
</div>

<style lang="scss">
  .notifications-container {
    position: relative;
  }

  .notifications-toggle {
    background: none;
    border: none;
    color: var(--text-color);
    cursor: pointer;
    position: relative;

    .badge {
      position: absolute;
      top: -5px;
      right: -5px;
      background: #ff6b6b;
      color: white;
      width: 18px;
      height: 18px;
      border-radius: 50%;
      font-size: 12px;
      display: flex;
      justify-content: center;
      align-items: center;
    }
  }

  .notifications-dropdown {
    position: absolute;
    top: 40px;
    right: 0;
    width: 300px;
    background: var(--sidebar-bg);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 15px;
    z-index: 1001;

    p {
      margin: 0;
    }

    ul {
      list-style: none;
      padding: 0;
      margin: 0;
      display: flex;
      flex-direction: column;
      gap: 10px;

      li {
        padding: 10px;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.3s ease;

        &.unread {
          background: var(--selected-bg);
        }

        &:hover {
          background: var(--hover-bg);
        }

        p {
          font-size: 0.9em;
        }

        span {
          font-size: 0.8em;
          color: var(--placeholder-color);
        }
      }
    }
  }
</style>
