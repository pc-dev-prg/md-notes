<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import NotePreviewer from '$lib/components/NotePreviewer.svelte';

  let note = null;

  onMount(async () => {
    const { data, error } = await supabase
      .from('notes')
      .select('*')
      .eq('public_id', $page.params.public_id)
      .eq('is_public', true)
      .single();

    if (error) {
      console.error('Error fetching note:', error);
    } else {
      note = data;
    }
  });
</script>

<main>
  {#if note}
    <h1>{note.title}</h1>
    <NotePreviewer content={note.content} />
  {:else}
    <p>Note not found or is not public.</p>
  {/if}
</main>

<style lang="scss">
  main {
    padding: 20px;
  }
</style>
