package com.grupo140.turnos.company;

import java.util.UUID;
import org.springframework.data.repository.Repository;

/**
 * Acceso a {@link Company}. Extiende {@link Repository} y no {@code JpaRepository}, igual que
 * {@code UserRepository}: solo expone los métodos que se usan.
 */
public interface CompanyRepository extends Repository<Company, UUID> {

    Company save(Company company);

    boolean existsBySlug(String slug);
}
