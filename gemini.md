# Project: MD Notes

## 1. Project Overview & Persona

You are a senior full-stack web developer with a strong sense for aesthetic design and modern UX.

Your task is to build **MD Notes**: a modern, elegant, and futuristic Markdown-based note-taking web application. The primary focus is on a sleek user interface, a seamless user experience, and a robust, secure backend.

## 2. Core Philosophy & Design System

The application's aesthetic is paramount. It should feel like a high-end tool from a sci-fi movie—minimalistic, functional, and visually striking.

### 2.1. Aesthetic
- **Overall Feel:** Sleek, modern, minimalistic, futuristic, elegant.
- **UI/UX:** Focus on subtle transitions, micro-interactions, and a clean, uncluttered layout. Every element must feel intentional. Avoid harsh corners; use subtle `border-radius` where appropriate.

### 2.2. Color Palette
The application will use a dark theme exclusively.
- **Primary Background:** `#0a0a0a` (Almost Black)
- **Accent 1 (Interactive Elements):** A bright, futuristic light blue. Example: `#00aaff`
- **Accent 2 (Highlights, Gradients):** A deep, elegant purple. Example: `#9c27b0`
- **Primary Text:** A light gray/off-white for readability. Example: `#e0e0e0`
- **Secondary Text/Icons:** A dimmer gray. Example: `#888888`

### 2.3. Typography
- **Font:** Use a clean, readable sans-serif font. A modern system font stack or a Google Font like `Inter` or `Nunito Sans` is preferred.
- **Hierarchy:** Establish a clear visual hierarchy with font sizes and weights.

## 3. Technology Stack

- **Frontend Framework:** **SvelteKit**
- **Backend & Database:** **Supabase** (Auth, Postgres Database, Realtime, Storage)
- **Styling:** **Svelte's scoped `<style>` blocks** or SCSS modules.
  - **CRITICAL CONSTRAINT: Do NOT use Tailwind CSS.**
  - All styles should be clean, well-organized, and reusable. Use CSS variables for the color palette.

## 4. Functional Requirements

### 4.1. Landing Page
- A stylish, single-page presentation of MD Notes.
- **Header:**
  - Top-left: A simple, text-based logo ("MD Notes").
  - Top-right: "Sign In / Register" button.
- **Hero Section:** A central call-to-action (CTA) that prompts users to sign in. Use subtle, elegant gradients incorporating the accent colors (blue/purple).
- **Footer:** Minimal, with project name and year.

### 4.2. Authentication
- **Provider:** Supabase Auth.
- **Method:** **Magic Link authentication via email ONLY.** Do not implement password-based login.
- **Flow:**
  1. User enters their email.
  2. A magic link is sent to their email.
  3. Clicking the link signs them in and redirects them to the main application.
  4. Securely manage the user session on the client side.

### 4.3. Main Application Layout (Post-Login)
A three-column or two-pane layout is standard.

- **Header:** A slim top bar containing the "MD Notes" logo and a Logout/Profile icon on the far right.
- **Left Sidebar (File Tree):**
  - Displays a hierarchical list of the user's **projects**.
  - Under each project, display **folders** and **notes**. Folders can be nested infinitely.
  - **Drag-and-Drop:** Implement smooth drag-and-drop functionality to re-order and re-parent notes and folders.
  - A "New Project" or "New Note" button should be present.
- **Main Content View (Editor):**
  - This area displays the selected note.
  - **Modes:** Implement a clear toggle between **"Edit Mode"** and **"Preview Mode"**.
  - **Editor:** A clean text area with a monospaced font for Markdown editing. Must support syntax highlighting.
  - **Previewer:** Renders the Markdown content into styled HTML.
  - **Autosave:** Notes must be saved automatically a few seconds after the user stops typing.

### 4.4. Core Features
- **Realtime Sync:** Use Supabase Realtime to sync changes to notes, folders, and projects across all of a user's open sessions.
- **Responsive Design:** The app must be usable on tablet and mobile devices. The sidebar may collapse into a menu on smaller screens.

## 5. Backend & Data Model (Supabase)

### 5.1. Database Tables
- `profiles`: (Managed by Supabase Auth) Stores user-specific data, linked via `id` to `auth.users`.
- `projects`:
  - `id` (uuid, pk)
  - `user_id` (uuid, fk to `auth.users.id`)
  - `name` (text)
  - `created_at` (timestamptz)
- `folders`:
  - `id` (uuid, pk)
  - `user_id` (uuid, fk to `auth.users.id`)
  - `project_id` (uuid, fk to `projects.id`)
  - `parent_folder_id` (uuid, self-referencing fk to `folders.id`, nullable for root folders)
  - `name` (text)
  - `created_at` (timestamptz)
- `notes`:
  - `id` (uuid, pk)
  - `user_id` (uuid, fk to `auth.users.id`)
  - `project_id` (uuid, fk to `projects.id`)
  - `folder_id` (uuid, fk to `folders.id`, nullable for notes at project root)
  - `title` (text)
  - `content` (text)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

### 5.2. Row Level Security (RLS)
- **Enable RLS on ALL tables.**
- Create policies to ensure users can only `SELECT`, `INSERT`, `UPDATE`, and `DELETE` their own data.
- The standard policy condition will be `auth.uid() = user_id`.

### 5.3. Realtime
- Enable Supabase Realtime publications on the `projects`, `folders`, and `notes` tables.

## 6. Code & Style Guidelines

- **Architecture:** Use a component-driven architecture. Create small, reusable components (e.g., `Button.svelte`, `Input.svelte`, `FileTreeNode.svelte`).
- **File Structure:** Maintain a logical file structure within the `src` directory (e.g., `src/lib/components`, `src/lib/db`, `src/routes`).
- **Code Quality:** Write clean, modular, and readable Svelte and TypeScript/JavaScript code. Add comments where the logic is complex.