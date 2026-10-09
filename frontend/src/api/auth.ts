import type { ApiError, LoginRequest, LoginResponse } from '../types/Auth'

const API_URL = import.meta.env.VITE_API_URL
const FAKE_LOGIN = import.meta.env.VITE_FAKE_LOGIN === 'true'

export class ApiRequestError extends Error {
  code: string

  constructor(error: ApiError) {
    super(error.message)
    this.code = error.code
  }
}

export async function login(request: LoginRequest): Promise<LoginResponse> {
  // TEMPORAL: se borra cuando exista POST /api/auth/login en el backend.
  if (FAKE_LOGIN) {
    return fakeLogin(request)
  }

  let response: Response
  try {
    response = await fetch(`${API_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request),
    })
  } catch {
    throw new ApiRequestError({
      code: 'NETWORK_ERROR',
      message: 'No se pudo conectar con el servidor. Intentá de nuevo.',
    })
  }

  if (!response.ok) {
    throw new ApiRequestError(await response.json())
  }

  return response.json()
}

// TEMPORAL: respuesta falsa con la forma del contrato, usando los emails del seed.
async function fakeLogin(request: LoginRequest): Promise<LoginResponse> {
  if (request.email === 'superadmin@example.com') {
    return {
      token: 'fake-token-superadmin',
      user: {
        id: 'fake-superadmin-id',
        firstName: 'Super',
        lastName: 'Admin',
        email: request.email,
        role: 'SUPERADMIN',
        companyId: null,
      },
    }
  }

  if (request.email === 'admin@example.com') {
    return {
      token: 'fake-token-admin',
      user: {
        id: 'fake-admin-id',
        firstName: 'Admin',
        lastName: 'Barbería',
        email: request.email,
        role: 'COMPANY_ADMIN',
        companyId: 'fake-company-id',
      },
    }
  }

  // Código provisorio: el nombre definitivo lo define el backend.
  if (request.email === 'admin.pendiente@example.com') {
    throw new ApiRequestError({
      code: 'ACCOUNT_NOT_ACTIVATED',
      message: 'Tu cuenta todavía no está activada',
    })
  }

  throw new ApiRequestError({
    code: 'INVALID_CREDENTIALS',
    message: 'Email o contraseña incorrectos',
  })
}
