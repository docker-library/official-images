public class container {
	/**
	 * Check if dotted env vars are supported.
	 */
	public static void main(String[] args) {
		// get value of variable.with.a.dot and print it out
		String value = System.getenv("variable.with.a.dot");
		System.out.println(value);
		System.exit(0);
	}
}
