// Theme and accent for the admin panel, remembered per browser.
//
// Kept apart from a site's own theme: someone can run the panel dark while the
// site they are building is light.

const THEME_KEY = 'yulia-theme';
const ACCENT_KEY = 'yulia-accent';

export const ACCENTS = [
  { id: 'teal', label: 'Бирюзовый', hex: '#00b294' },
  { id: 'azure', label: 'Синий', hex: '#0078d4' },
  { id: 'magenta', label: 'Пурпурный', hex: '#e3008c' },
  { id: 'amber', label: 'Янтарный', hex: '#e88c00' },
  { id: 'violet', label: 'Фиолетовый', hex: '#8764b8' },
  { id: 'lime', label: 'Лаймовый', hex: '#7cbb00' }
] as const;

function stored(key: string, fallback: string): string {
  try {
    return localStorage.getItem(key) || fallback;
  } catch {
    // Private browsing refuses storage; the default look is fine there.
    return fallback;
  }
}

function persist(key: string, value: string): void {
  try {
    localStorage.setItem(key, value);
  } catch {
    /* nothing to do: the choice simply is not remembered */
  }
}

class Appearance {
  theme = $state(stored(THEME_KEY, 'dark'));
  accent = $state(stored(ACCENT_KEY, 'teal'));

  apply(): void {
    const root = document.documentElement;
    root.setAttribute('data-theme', this.theme);
    root.setAttribute('data-accent', this.accent);
  }

  setTheme(value: string): void {
    this.theme = value;
    persist(THEME_KEY, value);
    this.apply();
  }

  toggleTheme(): void {
    this.setTheme(this.theme === 'dark' ? 'light' : 'dark');
  }

  setAccent(value: string): void {
    this.accent = value;
    persist(ACCENT_KEY, value);
    this.apply();
  }
}

export const appearance = new Appearance();
