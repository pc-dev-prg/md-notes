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
    background: transparent;
    color: #e0e0e0;
    padding: 20px;
    overflow-y: auto;
  }

  :global(table) {
    width: 100%;
    border-collapse: collapse;
    margin: 20px 0;
  }

  :global(th),
  :global(td) {
    border: 1px solid rgba(255, 255, 255, 0.2);
    padding: 10px;
    text-align: left;
  }

  :global(th) {
    background-color: rgba(255, 255, 255, 0.1);
  }

  :global(blockquote) {
    border-left: 3px solid #00bfff;
    padding-left: 15px;
    margin-left: 0;
    color: #a0a0a0;
    font-style: italic;
  }

  :global(a) {
    color: #00bfff;
    text-decoration: none;
  }

  :global(a:hover) {
    text-decoration: underline;
  }
</style>
