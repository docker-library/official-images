<?php
if (!defined('PASSWORD_ARGON2I')) {
	echo "FAIL: Constant PASSWORD_ARGON2I is not defined.\n";
	exit(1);
}

// Test vector generated using:
// var_dump(password_hash('password', PASSWORD_ARGON2I, ['memory_cost' => 1<<3, 'time_cost' => 1, 'threads' => 1]));
if (!password_verify('password', '$argon2i$v=19$m=8,t=1,p=1$RWxaRlZ0d1FTa3RSY1c1OQ$c7a/rJlPgvH9ItPi74UGuh0tdCBhpdDF7b/nA3QweX8')) {
	echo "FAIL: Failed to check test vector.\n";
	exit(1);
}
exit(0);
