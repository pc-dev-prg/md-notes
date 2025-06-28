<script>
  import { marked } from 'marked';

  export let content = '';

  marked.setOptions({
    gfm: true,
    breaks: true,
  });

  $: renderedContent = marked(content);
</script>

<div class="note-previewer">
  {@html renderedContent}
</div>

<style>
  .note-previewer {
    width: 100%;
    height: 100%;
    background-color: #1a1a1a;
    color: #f0f0f0;
    border: 1px solid #8a2be2;
    border-radius: 5px;
    padding: 15px;
    overflow-y: auto;
  }

  :global(table) {
    width: 100%;
    border-collapse: collapse;
    margin: 20px 0;
  }

  :global(th),
  :global(td) {
    border: 1px solid #8a2be2;
    padding: 10px;
    text-align: left;
  }

  :global(th) {
    background-color: #8a2be2;
    color: white;
  }
</style>
