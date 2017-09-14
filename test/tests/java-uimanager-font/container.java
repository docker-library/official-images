import javax.swing.LookAndFeel;
import javax.swing.UIManager;

public class container {
	static int exitVal = 0;

	/**
	 * Tests the UIManager a bit.	Doing this kills a lot of OpenJDK builds.
	 *
	 * Note these functions are used in a headless application, a web app.
	 * The fonts are needed to create PDFs reliably.
	 *
	 * If this succeeds, the first line it prints to stdout is Success
	 * and it returns a return code (exit value) of 0 (zero)
	 *
	 * If there's a failure, the first line consists of Failed, and the return code is 1 (one)
	 */
	public static void main(String[] args) {
		
		try {
			String family = UIManager.getFont("Label.font").getFamily();
		} catch (Throwable t) {
			bad("Could not get the default font's family", t);
		}

		try {
			LookAndFeel look = UIManager.getLookAndFeel();
		} catch (Throwable t) {
			bad("Error getting the look and feel class name", t);
		}

		try {
			LookAndFeel metal = new javax.swing.plaf.metal.MetalLookAndFeel();
			UIManager.setLookAndFeel(metal);
			String family = UIManager.getFont("Label.font").getFamily();
		} catch (Throwable t) {
			bad("Error making a Metal look/feel, setting it to the UIManager, or getting its font...", t);
		}

		System.exit(exitVal);
	}

	private static void bad(String msg, Throwable t) {
		exitVal = 1;
		System.err.println(msg);
		t.printStackTrace(System.err);
	}
}
