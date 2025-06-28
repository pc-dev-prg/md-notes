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
  let bio = '';
  let fullName = '';
  let websiteUrl = '';
  let twitterUrl = '';

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
        bio = profile.bio || '';
        fullName = profile.full_name || '';
        websiteUrl = profile.website_url || '';
        twitterUrl = profile.twitter_url || '';
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

  const updateProfile = async () => {
    const { error } = await supabase
      .from('profiles')
      .update({
        bio,
        full_name: fullName,
        website_url: websiteUrl,
        twitter_url: twitterUrl,
      })
      .eq('id', session.user.id);

    if (error) {
      console.error('Error updating profile:', error);
      alert('Error updating profile.');
    } else {
      alert('Profile updated successfully.');
    }
  };
</script>

<main>
  <h1>Profile</h1>
  {#if profile}
    <div class="profile-card">
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
      <div class="profile-details">
        <h2>{profile.username}</h2>
        <input type="text" placeholder="Full Name" bind:value={fullName} />
        <input type="text" placeholder="Website URL" bind:value={websiteUrl} />
        <input type="text" placeholder="Twitter URL" bind:value={twitterUrl} />
        <textarea placeholder="Tell us about yourself..." bind:value={bio}></textarea>
        <button on:click={updateProfile}>Save Profile</button>
      </div>
    </div>
  {/if}
</main>

<style lang="scss">
  main {
    padding: 20px;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .profile-card {
    display: flex;
    gap: 30px;
    background: var(--sidebar-bg);
    padding: 30px;
    border-radius: 12px;
    border: 1px solid var(--border-color);
    width: 100%;
    max-width: 600px;
  }

  .avatar-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 15px;

    img {
      width: 150px;
      height: 150px;
      border-radius: 50%;
      object-fit: cover;
    }

    label {
      cursor: pointer;
      background: var(--accent-color);
      color: white;
      padding: 10px 15px;
      border-radius: 8px;
      text-align: center;
    }

    input[type='file'] {
      display: none;
    }
  }

  .profile-details {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    gap: 15px;

    h2 {
      margin: 0;
      font-size: 1.8em;
    }

    input,
    textarea {
      width: 100%;
      padding: 10px;
      border-radius: 8px;
      border: 1px solid var(--border-color);
      background: var(--input-bg);
      color: var(--text-color);
      font-family: 'Inter', sans-serif;
      resize: none;
    }

    button {
      background: var(--accent-color);
      border: none;
      padding: 10px 15px;
      border-radius: 8px;
      color: #fff;
      font-size: 1em;
      cursor: pointer;
      align-self: flex-start;
    }
  }
</style>
