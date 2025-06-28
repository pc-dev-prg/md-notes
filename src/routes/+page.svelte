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
  <div class="background-shapes"></div>
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
    background-color: #0d0d0d;
    color: #e0e0e0;
    font-family: 'Inter', sans-serif;
  }

  main {
    position: relative;
    display: flex;
    flex-direction: column;
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
    background: #0d0d0d;

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
      left: -50px;
    }

    &::after {
      width: 400px;
      height: 400px;
      background: rgba(138, 43, 226, 0.2);
      bottom: -100px;
      right: -100px;
    }
  }

  header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 40px;
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(10px);
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);

    .logo {
      font-size: 1.5em;
      font-weight: 700;
      color: #fff;
    }

    button {
      background: rgba(255, 255, 255, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.2);
      padding: 10px 20px;
      border-radius: 8px;
      color: white;
      font-size: 1em;
      cursor: pointer;
      transition: all 0.3s ease;

      &:hover {
        background: rgba(255, 255, 255, 0.2);
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
      font-size: 4em;
      font-weight: 800;
      color: #fff;
      margin-bottom: 20px;
    }

    p {
      font-size: 1.2em;
      color: #a0a0a0;
      margin-bottom: 40px;
    }

    .auth-card {
      background: rgba(255, 255, 255, 0.05);
      backdrop-filter: blur(10px);
      padding: 40px;
      border-radius: 16px;
      border: 1px solid rgba(255, 255, 255, 0.1);
      width: 100%;
      max-width: 400px;

      h2 {
        color: #fff;
        margin-bottom: 30px;
        font-size: 1.5em;
        font-weight: 600;
      }

      form {
        display: flex;
        flex-direction: column;
        gap: 20px;

        input {
          padding: 15px;
          border: 1px solid rgba(255, 255, 255, 0.2);
          border-radius: 8px;
          background: rgba(255, 255, 255, 0.1);
          color: #fff;
          font-size: 1em;

          &::placeholder {
            color: #a0a0a0;
          }

          &:focus {
            outline: none;
            border-color: #00bfff;
          }
        }

        button {
          background: #00bfff;
          border: none;
          padding: 15px;
          border-radius: 8px;
          color: white;
          font-size: 1.1em;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.3s ease;

          &:hover {
            background: #00a0cc;
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

    button {
      background: none;
      border: none;
      color: #a0a0a0;
      cursor: pointer;
      font-size: 0.9em;

      &:hover {
        color: #fff;
      }
    }
  }

  @media (max-width: 768px) {
    header {
      padding: 15px 20px;
    }

    .hero {
      h1 {
        font-size: 3em;
      }

      p {
        font-size: 1em;
      }

      .auth-card {
        padding: 30px;
      }
    }
  }
</style>
