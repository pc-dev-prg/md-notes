<script>
	import { supabase } from '$lib/supabaseClient';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { sessionStore } from '$lib/store';
	import { sineIn } from 'svelte/easing';
	import { fly } from 'svelte/transition';

	let email = '';
	let loading = false;
	let message = '';
	let session;
	let showModal = false;

	sessionStore.subscribe((value) => {
		session = value;
	});

	onMount(() => {
		supabase.auth.getSession().then(({ data }) => {
			sessionStore.set(data.session);
			if (data.session) {
				goto('/dashboard');
			}
		});

		const { data: authListener } = supabase.auth.onAuthStateChange((_event, newSession) => {
			sessionStore.set(newSession);
			if (newSession) {
				goto('/dashboard');
			}
		});

		return () => {
			authListener.subscription.unsubscribe();
		};
	});

	const handleLogin = async () => {
		try {
			loading = true;
			message = '';
			const { error } = await supabase.auth.signInWithOtp({
				email: email,
				options: {
					shouldCreateUser: true,
					emailRedirectTo: `${window.location.origin}/dashboard`
				}
			});

			if (error) {
				throw error;
			}

			message = 'Check your email for the magic link!';
		} catch (error) {
			message = error.message;
		} finally {
			loading = false;
		}
	};

	const continueAsGuest = () => {
		const guestSession = { user: { id: 'guest' } };
		sessionStore.set(guestSession);
		localStorage.setItem('session', JSON.stringify(guestSession));
		goto('/dashboard');
	};
</script>

<div class="landing-container">
	<div class="background-shapes"></div>
	<header>
		<div class="logo">MD Notes</div>
		<nav>
			<button on:click={() => (showModal = true)}>Sign In / Register</button>
		</nav>
	</header>

	<main>
		<section class="hero">
			<div class="hero-content">
				<h1
					in:fly={{ y: -20, duration: 800, delay: 200, easing: sineIn }}
					out:fly={{ y: -20, duration: 400, easing: sineIn }}
				>
					Your Ideas, Beautifully Organized
				</h1>
				<p
					in:fly={{ y: -20, duration: 800, delay: 400, easing: sineIn }}
					out:fly={{ y: -20, duration: 400, easing: sineIn }}
				>
					MD Notes is a sleek, futuristic Markdown editor designed for clarity and focus.
				</p>
				<div
					class="cta-buttons"
					in:fly={{ y: -20, duration: 800, delay: 600, easing: sineIn }}
					out:fly={{ y: -20, duration: 400, easing: sineIn }}
				>
					<button class="primary" on:click={() => (showModal = true)}>Get Started</button>
					<button class="secondary" on:click={continueAsGuest}>Continue as Guest</button>
				</div>
			</div>
			<div
				class="hero-image"
				in:fly={{ y: 20, duration: 800, delay: 800, easing: sineIn }}
				out:fly={{ y: 20, duration: 400, easing: sineIn }}
			>
				<img src="https://placehold.co/800x600/0a0a0a/e0e0e0?text=MD+Notes" alt="App Screenshot" />
			</div>
		</section>

		<section class="features">
			<div class="feature">
				<img src="https://placehold.co/400x300/0a0a0a/00aaff?text=Real-time+Sync" alt="Real-time Sync" />
				<h3>Real-time Sync</h3>
				<p>Keep your notes updated across all devices, instantly.</p>
			</div>
			<div class="feature">
				<img
					src="https://placehold.co/400x300/0a0a0a/9c27b0?text=Markdown+Preview"
					alt="Markdown Preview"
				/>
				<h3>Markdown Preview</h3>
				<p>See your formatted text as you type with a live preview.</p>
			</div>
			<div class="feature">
				<img
					src="https://placehold.co/400x300/0a0a0a/e0e0e0?text=Secure+Authentication"
					alt="Secure Authentication"
				/>
				<h3>Secure Authentication</h3>
				<p>Magic link login ensures your notes are safe and sound.</p>
			</div>
		</section>
	</main>

	<footer>
		<p>&copy; 2025 MD Notes. All rights reserved.</p>
	</footer>
</div>

{#if showModal}
	<div class="modal-overlay" on:click={() => (showModal = false)}>
		<div class="modal" on:click|stopPropagation>
			<h2>Sign in / Register</h2>
			<form on:submit|preventDefault={handleLogin}>
				<input type="email" placeholder="Your email" bind:value={email} />
				<button type="submit" disabled={loading}>
					{#if loading}Sending...{:else}Send Magic Link{/if}
				</button>
			</form>
			{#if message}
				<p class="message">{message}</p>
			{/if}
		</div>
	</div>
{/if}

<style lang="scss">
	:global(body) {
		margin: 0;
		background-color: #0a0a0a;
		color: #e0e0e0;
		font-family: 'Inter', sans-serif;
	}

	.landing-container {
		position: relative;
		overflow-x: hidden;
	}

	.background-shapes {
		position: absolute;
		top: 0;
		left: 0;
		width: 100%;
		height: 100%;
		z-index: -1;
		background: #0a0a0a;

		&::before,
		&::after {
			content: '';
			position: absolute;
			border-radius: 50%;
			filter: blur(150px);
			opacity: 0.2;
		}

		&::before {
			width: 400px;
			height: 400px;
			background: #00aaff;
			top: -100px;
			left: -100px;
		}

		&::after {
			width: 500px;
			height: 500px;
			background: #9c27b0;
			bottom: -200px;
			right: -200px;
		}
	}

	header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 20px 40px;
		background: rgba(10, 10, 10, 0.5);
		backdrop-filter: blur(10px);
		border-bottom: 1px solid rgba(255, 255, 255, 0.08);
		position: sticky;
		top: 0;
		z-index: 10;

		.logo {
			font-size: 1.5em;
			font-weight: 700;
			color: #e0e0e0;
		}

		nav button {
			background: transparent;
			border: 1px solid #00aaff;
			padding: 10px 20px;
			border-radius: 8px;
			color: #00aaff;
			font-size: 1em;
			cursor: pointer;
			transition: all 0.3s ease;

			&:hover {
				background: rgba(0, 170, 255, 0.1);
				color: #fff;
			}
		}
	}

	main {
		padding: 0 40px;
	}

	.hero {
		display: grid;
		grid-template-columns: 1fr 1fr;
		align-items: center;
		gap: 60px;
		min-height: 80vh;
		padding: 80px 0;

		.hero-content {
			h1 {
				font-size: 4em;
				font-weight: 800;
				color: #fff;
				margin-bottom: 20px;
				line-height: 1.2;
			}

			p {
				font-size: 1.2em;
				color: #888888;
				margin-bottom: 40px;
				max-width: 500px;
			}

			.cta-buttons {
				display: flex;
				gap: 20px;

				button {
					padding: 15px 30px;
					border-radius: 8px;
					font-size: 1.1em;
					font-weight: 600;
					cursor: pointer;
					transition: all 0.3s ease;
				}

				.primary {
					background: #00aaff;
					border: none;
					color: #0a0a0a;

					&:hover {
						background: #33bbff;
					}
				}

				.secondary {
					background: transparent;
					border: 1px solid #888888;
					color: #888888;

					&:hover {
						border-color: #fff;
						color: #fff;
					}
				}
			}
		}

		.hero-image img {
			width: 100%;
			border-radius: 16px;
			box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
		}
	}

	.features {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		gap: 40px;
		padding: 80px 0;
		text-align: center;

		.feature {
			img {
				width: 100%;
				border-radius: 12px;
				margin-bottom: 20px;
			}

			h3 {
				font-size: 1.5em;
				font-weight: 600;
				color: #fff;
				margin-bottom: 10px;
			}

			p {
				color: #888888;
			}
		}
	}

	footer {
		text-align: center;
		padding: 40px;
		border-top: 1px solid rgba(255, 255, 255, 0.08);
		color: #888888;
	}

	.modal-overlay {
		position: fixed;
		top: 0;
		left: 0;
		width: 100%;
		height: 100%;
		background: rgba(0, 0, 0, 0.7);
		backdrop-filter: blur(10px);
		display: flex;
		justify-content: center;
		align-items: center;
		z-index: 1000;
	}

	.modal {
		background: rgba(20, 20, 20, 0.8);
		padding: 40px;
		border-radius: 16px;
		border: 1px solid rgba(255, 255, 255, 0.1);
		width: 100%;
		max-width: 400px;

		h2 {
			color: #e0e0e0;
			margin-bottom: 30px;
			font-size: 1.5em;
			font-weight: 600;
			text-align: center;
		}

		form {
			display: flex;
			flex-direction: column;
			gap: 20px;

			input {
				padding: 15px;
				border: 1px solid rgba(255, 255, 255, 0.1);
				border-radius: 8px;
				background: rgba(0, 0, 0, 0.2);
				color: #e0e0e0;
				font-size: 1em;

				&::placeholder {
					color: #888888;
				}

				&:focus {
					outline: none;
					border-color: #00aaff;
				}
			}

			button {
				background: #00aaff;
				border: none;
				padding: 15px;
				border-radius: 8px;
				color: #0a0a0a;
				font-size: 1.1em;
				font-weight: 600;
				cursor: pointer;
				transition: all 0.3s ease;

				&:hover {
					background: #33bbff;
				}

				&:disabled {
					background: #555;
					color: #888;
					cursor: not-allowed;
				}
			}
		}

		.message {
			margin-top: 20px;
			color: #00aaff;
			font-size: 1em;
			text-align: center;
		}
	}

	@media (max-width: 768px) {
		.hero {
			grid-template-columns: 1fr;
			text-align: center;

			.hero-content {
				.cta-buttons {
					justify-content: center;
				}
			}
		}
	}
</style>
