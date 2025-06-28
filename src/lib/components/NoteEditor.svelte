<script>
  export let content = '';
</script>

<div class="note-editor">
  <textarea bind:value={content} placeholder="Start writing..."></textarea>
</div>

<style>
  .note-editor {
    width: 100%;
    height: 100%;
  }

  textarea {
    width: 100%;
    height: 100%;
    background: transparent;
    color: #e0e0e0;
    border: none;
    padding: 20px;
    font-family: 'Inter', sans-serif;
    font-size: 1em;
    resize: none;

    &:focus {
      outline: none;
    }

    &::placeholder {
      color: #a0a0a0;
    }
  }
</style>
