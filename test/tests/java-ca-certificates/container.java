import java.net.URL;

public class container {
	public static void main(String[] args) {
		try {
			new URL("https://google.com").openStream(); // force a CA certificate lookup
			System.exit(0);
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		System.exit(1);
	}
}
