import { writable } from 'svelte/store';

export const sessionStore = writable(null);
export const projectsStore = writable([]);
export const selectedProjectStore = writable(null);