export type UserRole = 'SUPERADMIN' | 'COMPANY_ADMIN' | 'CLIENT'

export type UserStatus = 'PENDING_ACTIVATION' | 'ACTIVE' | 'INACTIVE'

export interface User {
  id: string
  firstName: string
  lastName: string
  email: string
  phone: string
  role: UserRole
  // Nulo solo para SUPERADMIN (ver diccionario-datos.md).
  companyId: string | null
  status: UserStatus
  createdAt: string
  updatedAt: string
}
