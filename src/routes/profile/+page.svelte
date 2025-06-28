<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';
  import { sessionStore } from '$lib/store';

  let session;
  sessionStore.subscribe((value) => {
    session = value;
  });

  let profile = null;
  let avatarUrl = null;
  let uploading = false;

  onMount(async () => {
    if (session) {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single();

      if (error) {
        console.error('Error fetching profile:', error);
      } else {
        profile = data;
        avatarUrl = profile.avatar_url;
      }
    }
  });

  const uploadAvatar = async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    uploading = true;
    const { data, error } = await supabase.storage
      .from('avatars')
      .upload(`${session.user.id}/${Date.now()}`, file);

    if (error) {
      console.error('Error uploading avatar:', error);
      alert('Error uploading avatar.');
      uploading = false;
      return;
    }

    const { publicURL, error: urlError } = supabase.storage
      .from('avatars')
      .getPublicUrl(data.path);

    if (urlError) {
      console.error('Error getting public URL:', urlError);
      alert('Error getting public URL.');
      uploading = false;
      return;
    }

    const { error: updateError } = await supabase
      .from('profiles')
      .update({ avatar_url: publicURL })
      .eq('id', session.user.id);

    if (updateError) {
      console.error('Error updating profile:', updateError);
      alert('Error updating profile.');
    } else {
      avatarUrl = publicURL;
    }

    uploading = false;
  };
</script>

<main>
  <h1>Profile</h1>
  {#if profile}
    <div class="avatar-container">
      <img src={avatarUrl || 'https://via.placeholder.com/150'} alt="Avatar" />
      <label for="avatar-upload">
        {uploading ? 'Uploading...' : 'Upload Avatar'}
      </label>
      <input
        id="avatar-upload"
        type="file"
        accept="image/*"
        on:change={uploadAvatar}
        disabled={uploading}
      />
    </div>
    <p>Username: {profile.username}</p>
  {/if}
</main>

<style lang="scss">
  main {
    padding: 20px;
  }

  .avatar-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
    margin-bottom: 20px;

    img {
      width: 150px;
      height: 150px;
      border-radius: 50%;
      object-fit: cover;
    }

    label {
      cursor: pointer;
      background: #00bfff;
      color: white;
      padding: 10px 15px;
      border-radius: 8px;
    }

    input[type='file'] {
      display: none;
    }
  }
</style>
