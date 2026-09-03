// Who is signed in, and how far through signing in they are.

import { api, setCsrfToken } from './api';

export interface User {
  id: number;
  email: string;
  name: string;
  role: string;
  second_factor_enrolled: boolean;
}

type Stage = 'loading' | 'setup' | 'signed-out' | 'second-factor' | 'enrol' | 'ready';

class SessionStore {
  stage = $state<Stage>('loading');
  user = $state<User | null>(null);

  // Held between the password step and the code step. Nothing is written to the
  // database until the second factor is accepted.
  challenge = $state<string | null>(null);
  methods = $state<string[]>([]);

  async load(): Promise<void> {
    const setup = await api.get<{ needs_setup: boolean }>('/api/setup');
    const session = await api.get<{ signed_in: boolean; csrf_token: string; user?: User }>(
      '/api/session'
    );
    setCsrfToken(session.csrf_token);

    if (setup.needs_setup) {
      this.stage = 'setup';
      return;
    }

    if (!session.signed_in) {
      this.stage = 'signed-out';
      return;
    }

    this.user = session.user ?? null;
    this.stage = this.user?.second_factor_enrolled ? 'ready' : 'enrol';
  }

  async signIn(email: string, password: string): Promise<void> {
    const result = await api.post<{
      challenge?: string;
      methods?: string[];
      user?: User;
      next?: string;
    }>('/api/session', { session: { email, password } });

    if (result.challenge) {
      this.challenge = result.challenge;
      this.methods = result.methods ?? [];
      this.stage = 'second-factor';
      return;
    }

    // An account with no second factor yet goes straight to enrolling one.
    this.user = result.user ?? null;
    this.stage = 'enrol';
    await this.refreshToken();
  }

  async submitSecondFactor(code: string): Promise<void> {
    const result = await api.post<{ user: User }>('/api/session/second_factor', {
      challenge: this.challenge,
      code
    });
    this.user = result.user;
    this.challenge = null;
    this.stage = 'ready';
    await this.refreshToken();
  }

  async completeSetup(fields: {
    email: string;
    name: string;
    password: string;
    password_confirmation: string;
  }): Promise<void> {
    const result = await api.post<{ user: User }>('/api/setup', { setup: fields });
    this.user = result.user;
    this.stage = 'enrol';
    await this.refreshToken();
  }

  finishEnrolment(): void {
    if (this.user) this.user.second_factor_enrolled = true;
    this.stage = 'ready';
  }

  async signOut(): Promise<void> {
    await api.delete('/api/session');
    this.user = null;
    this.stage = 'signed-out';
    await this.refreshToken();
  }

  // The token is tied to the session, so it has to be picked up again whenever
  // the session changes.
  private async refreshToken(): Promise<void> {
    const session = await api.get<{ csrf_token: string }>('/api/session');
    setCsrfToken(session.csrf_token);
  }
}

export const session = new SessionStore();
