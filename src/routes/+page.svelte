<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { sessionStore } from '$lib/store';

  let email = '';
  let loading = false;
  let session;

  sessionStore.subscribe((value) => {
    session = value;
  });

  let otp = '';
  const handleVerifyOtp = async () => {
    try {
      loading = true;
      const storedOtp = localStorage.getItem('otp');
      const storedEmail = localStorage.getItem('email');

      if (!storedOtp || !storedEmail || otp !== storedOtp) {
        alert('Invalid OTP. Please try again.');
        return;
      }

      const { data, error } = await supabase.auth.verifyOtp({
        email: storedEmail,
        token: otp,
        type: 'email',
      });

      if (error) {
        console.error('Error verifying OTP:', error);
        alert('Failed to verify OTP. Please try again.');
        throw error;
      }

      alert('Successfully signed in!');
    } catch (error) {
      alert(error.message);
    } finally {
      loading = false;
    }
  };

  onMount(() => {
    supabase.auth.getSession().then(({ data }) => {
      sessionStore.set(data.session);
    });

    supabase.auth.onAuthStateChange((_event, newSession) => {
      sessionStore.set(newSession);
    });
  });

  const handleLogin = async () => {
    try {
      loading = true;
      // Generate a random 6-digit OTP
      const otpValue = Math.floor(100000 + Math.random() * 900000);

      // Send the OTP via email using Supabase Functions or a third-party service
      // (This requires setting up a Supabase Function or integrating with a service like SendGrid)
      const { data, error } = await supabase.functions.invoke('send-otp', {
        body: {
          email: email,
          otp: otpValue,
        },
      });

      if (error) {
        console.error('Error sending OTP:', error);
        alert('Failed to send OTP. Please try again.');
        throw error;
      }

      // Store the OTP in local storage (for demonstration purposes only, not recommended for production)
      localStorage.setItem('otp', otpValue);
      localStorage.setItem('email', email);

      alert('Check your email for the OTP!');
    } catch (error) {
      alert(error.message);
    } finally {
      loading = false;
    }
  };

  const handleLogout = async () => {
    try {
      loading = true;
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
    } catch (error) {
      alert(error.message);
    } finally {
      loading = false;
    }
  };

  const continueAsGuest = () => {
    sessionStore.set({ user: { id: 'guest' } });
    goto('/dashboard');
  };
</script>

<main>
  <header>
    <div class="logo">MD Notes</div>
    {#if session}
      <button on:click={handleLogout} disabled={loading}>Logout</button>
    {:else}
      <button on:click={() => {}} disabled={loading}>Sign In / Register</button>
    {/if}
  </header>

  <section class="hero">
    <h1>Welcome to MD Notes</h1>
    <p>Your futuristic Markdown note-taking experience.</p>
    {#if !session}
      <div class="auth-card">
        <h2>Sign in with Magic Link</h2>
        <form on:submit|preventDefault={handleLogin}>
          <input type="email" placeholder="Your email" value="petr.cafourek@gmail.com" />
          <button type="submit" disabled={loading}>
            {#if loading}Loading...{:else}Send Magic Link{/if}
          </button>
        </form>
        <p>Check your email for the OTP!</p>
        <h2>Enter OTP</h2>
        <form on:submit|preventDefault={handleVerifyOtp}>
          <input type="text" placeholder="Enter OTP" bind:value={otp} />
          <button type="submit" disabled={loading}>
            {#if loading}Loading...{:else}Verify OTP{/if}
          </button>
        </form>
        <div class="guest-login">
          <button on:click={continueAsGuest}>Continue as Guest</button>
        </div>
      </div>
    {:else}
      <p>You are logged in! Go to your <a href="/dashboard">dashboard</a>.</p>
    {/if}
  </section>
</main>

<style lang="scss">
  :global(body) {
    margin: 0;
    background-color: #0a0a0a;
    color: #f0f0f0;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  }

  main {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
    background: linear-gradient(135deg, #0a0a0a 0%, #1a0a2a 100%);
  }

  header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 40px;
    background-color: rgba(0, 0, 0, 0.5);
    border-bottom: 1px solid rgba(138, 43, 226, 0.3);

    .logo {
      font-size: 1.8em;
      font-weight: bold;
      color: #00bfff;
      text-shadow: 0 0 10px rgba(0, 191, 255, 0.5);
    }

    button {
      background: linear-gradient(45deg, #00bfff, #8a2be2);
      border: none;
      padding: 10px 20px;
      border-radius: 5px;
      color: white;
      font-size: 1em;
      cursor: pointer;
      transition: all 0.3s ease;

      &:hover {
        opacity: 0.9;
        box-shadow: 0 0 15px rgba(0, 191, 255, 0.7);
      }

      &:disabled {
        background: #333;
        cursor: not-allowed;
      }
    }
  }

  .hero {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    text-align: center;
    padding: 20px;

    h1 {
      font-size: 3.5em;
      color: #00bfff;
      margin-bottom: 15px;
      text-shadow: 0 0 20px rgba(0, 191, 255, 0.6);
    }

    p {
      font-size: 1.5em;
      color: #ccc;
      margin-bottom: 40px;
    }

    .auth-card {
      background-color: rgba(25, 25, 25, 0.8);
      padding: 30px;
      border-radius: 10px;
      box-shadow: 0 0 30px rgba(138, 43, 226, 0.4);
      width: 100%;
      max-width: 400px;

      h2 {
        color: #8a2be2;
        margin-bottom: 25px;
        font-size: 1.8em;
      }

      form {
        display: flex;
        flex-direction: column;
        gap: 15px;

        input {
          padding: 12px;
          border: 1px solid #8a2be2;
          border-radius: 5px;
          background-color: #1a1a1a;
          color: #f0f0f0;
          font-size: 1em;

          &:focus {
            outline: none;
            border-color: #00bfff;
            box-shadow: 0 0 8px rgba(0, 191, 255, 0.5);
          }
        }

        button {
          background: linear-gradient(45deg, #00bfff, #8a2be2);
          border: none;
          padding: 12px;
          border-radius: 5px;
          color: white;
          font-size: 1.1em;
          cursor: pointer;
          transition: all 0.3s ease;

          &:hover {
            opacity: 0.9;
            box-shadow: 0 0 15px rgba(0, 191, 255, 0.7);
          }

          &:disabled {
            background: #333;
            cursor: not-allowed;
          }
        }
      }
    }

    a {
      color: #00bfff;
      text-decoration: none;
      font-weight: bold;

      &:hover {
        text-decoration: underline;
      }
    }
  }

  .guest-login {
    margin-top: 20px;
  }

  .auth-card {
    h2 {
      color: #40b4ff;
    }

    form {
      input {
        border-color: #40b4ff;
        background-color: #1a1a1a;
        color: #f0f0f0;

        &:focus {
          border-color: #8a2be2;
          box-shadow: 0 0 8px rgba(138, 43, 226, 0.5);
        }
      }

      button[type="submit"] {
        background: linear-gradient(45deg, #40b4ff, #8a2be2);

        &:hover {
          box-shadow: 0 0 15px rgba(138, 43, 226, 0.7);
        }
      }
    }
  }
</style>
