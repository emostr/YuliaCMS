// Talks to the Rails admin API.
//
// Everything the panel does goes through here so that the CSRF token, error
// shape and JSON handling live in one place rather than at every call site.

export class ApiError extends Error {
  status: number;
  code: string;
  messages: string[];

  constructor(status: number, code: string, messages: string[] = []) {
    super(messages[0] ?? code);
    this.status = status;
    this.code = code;
    this.messages = messages;
  }
}

let csrfToken = '';

export function setCsrfToken(token: string): void {
  csrfToken = token;
}

type Body = Record<string, unknown> | FormData | undefined;

async function request<T>(method: string, path: string, body?: Body): Promise<T> {
  const headers: Record<string, string> = { Accept: 'application/json' };
  let payload: BodyInit | undefined;

  if (body instanceof FormData) {
    // Let the browser set the multipart boundary; naming the content type here
    // would produce a header without one and the upload would fail.
    payload = body;
  } else if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
    payload = JSON.stringify(body);
  }

  if (method !== 'GET' && csrfToken) {
    headers['X-CSRF-Token'] = csrfToken;
  }

  const response = await fetch(path, {
    method,
    headers,
    body: payload,
    credentials: 'same-origin'
  });

  if (response.status === 204) return undefined as T;

  const text = await response.text();
  const data = text ? (JSON.parse(text) as Record<string, unknown>) : {};

  if (!response.ok) {
    throw new ApiError(
      response.status,
      String(data.error ?? 'error'),
      (data.messages as string[]) ?? []
    );
  }

  return data as T;
}

export const api = {
  get: <T>(path: string) => request<T>('GET', path),
  post: <T>(path: string, body?: Body) => request<T>('POST', path, body),
  patch: <T>(path: string, body?: Body) => request<T>('PATCH', path, body),
  delete: <T>(path: string) => request<T>('DELETE', path)
};

// Turns an API failure into a sentence somebody who is not a programmer can
// act on. Anything unrecognised falls back to the server's own wording.
export function errorMessage(error: unknown): string {
  if (!(error instanceof ApiError)) {
    return 'Не удалось связаться с сервером. Проверьте соединение.';
  }

  const known: Record<string, string> = {
    unauthorized: 'Нужно войти заново.',
    invalid_credentials: 'Неверная почта или пароль.',
    invalid_code: 'Код не подошёл. Проверьте время на телефоне и попробуйте ещё раз.',
    challenge_expired: 'Вход занял слишком много времени. Начните сначала.',
    too_many_attempts: 'Слишком много попыток. Подождите несколько минут.',
    locked: 'Аккаунт временно заблокирован из-за неудачных попыток входа.',
    second_factor_required: 'Сначала настройте второй фактор.',
    already_set_up: 'Эта установка уже настроена.',
    not_found: 'Не найдено.'
  };

  if (error.messages.length) return error.messages.join('. ');
  return known[error.code] ?? 'Что-то пошло не так.';
}
