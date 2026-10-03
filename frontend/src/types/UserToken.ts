export type TokenType = 'ACTIVATION' | 'PASSWORD_RESET'

export interface UserToken {
  id: string
  userId: string
  type: TokenType
  expiresAt: string
  // Nulo mientras no se usó.
  usedAt: string | null
  createdAt: string
}
