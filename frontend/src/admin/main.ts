import { mount } from 'svelte';
import App from './App.svelte';
import './app.css';
import { appearance } from './lib/theme.svelte';
import { router } from './lib/router.svelte';

// Applied before the first paint so the panel does not flash the default theme
// on its way to the one the user chose.
appearance.apply();
router.start();

const target = document.getElementById('app');
if (!target) throw new Error('#app is missing from the admin shell');

export default mount(App, { target });
