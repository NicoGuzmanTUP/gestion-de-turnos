package com.grupo140.turnos.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.grupo140.turnos.auth.TokenGenerator.GeneratedToken;
import org.junit.jupiter.api.Test;

class TokenGeneratorTest {

    private final TokenGenerator generator = new TokenGenerator();

    @Test
    void generatedHashMatchesHashOfPlainValue() {
        GeneratedToken token = generator.generate();

        // Es lo que permite buscar el token entrante por findByTokenHash.
        assertThat(generator.hash(token.plainValue())).isEqualTo(token.hash());
    }

    @Test
    void hashIsSha256HexAndNeverThePlainValue() {
        GeneratedToken token = generator.generate();

        assertThat(token.hash()).matches("^[0-9a-f]{64}$").isNotEqualTo(token.plainValue());
    }

    @Test
    void plainValueIsUrlSafe() {
        GeneratedToken token = generator.generate();

        // 32 bytes en base64url sin padding = 43 caracteres.
        assertThat(token.plainValue()).matches("^[A-Za-z0-9_-]{43}$");
    }

    @Test
    void twoTokensAreNeverEqual() {
        assertThat(generator.generate().plainValue())
                .isNotEqualTo(generator.generate().plainValue());
    }
}
