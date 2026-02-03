package Server;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class MainTest {

    @Test
    public void testPasswordHashing() {
        String password = "secretPassword";
        String hashed = Main.hashPassword(password);
        
        assertNotNull(hashed);
        assertNotEquals(password, hashed);
        assertTrue(Main.checkPassword(password, hashed));
    }
    
    @Test
    public void testPasswordMismatch() {
        String password = "secretPassword";
        String otherPassword = "wrongPassword";
        String hashed = Main.hashPassword(password);
        
        assertFalse(Main.checkPassword(otherPassword, hashed));
    }
}
