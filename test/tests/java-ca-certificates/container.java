import java.net.URL;

public class container {
	public static void main(String[] args) {
		try {
			// connect() does the TLS handshake but never reads the response, so the HTTP status (google.com answers 429 to rate-limited CI runners) does not matter
			new URL("https://google.com").openConnection().connect(); // force a CA certificate lookup
			System.exit(0);
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		System.exit(1);
	}
}
