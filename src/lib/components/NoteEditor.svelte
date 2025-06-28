<script>
  export let content = '';
</script>

<div class="note-editor">
  <textarea bind:value={content}></textarea>
</div>

<style>
  .note-editor {
    width: 100%;
    height: 100%;
  }

  textarea {
    width: 100%;
    height: 100%;
    background-color: #1a1a1a;
    color: #f0f0f0;
    border: 1px solid #8a2be2;
    border-radius: 5px;
    padding: 15px;
    font-family: 'Courier New', Courier, monospace;
  }
</style>
