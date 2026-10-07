package com.grupo140.turnos.auth;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.repository.Repository;

/**
 * Acceso a {@link UserToken}. El token entrante se busca siempre por su hash (ver {@link TokenGenerator}):
 * el valor en claro nunca se persiste.
 */
public interface UserTokenRepository extends Repository<UserToken, UUID> {

    UserToken save(UserToken token);

    Optional<UserToken> findByTokenHash(String tokenHash);
}
