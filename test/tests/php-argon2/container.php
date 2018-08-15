<?php
$success = true;

// Argon2 is supported for PHP >= 7.2 on Debian >= 9 or Alpine >= 3.8
if (file_exists('/etc/alpine-release')) {
	$baseImage = version_compare(file_get_contents('/etc/alpine-release'), '3.8.0') >= 0;
}
else if (file_exists('/etc/debian_version')) {
	$baseImage = version_compare(file_get_contents('/etc/debian_version'), '9.0') >= 0;
}
else {
	echo "Unknown base image\n";
	$success = false;
}

if ($baseImage && version_compare(PHP_VERSION, '7.2.0') >= 0) {
	if (!defined('PASSWORD_ARGON2I')) {
		echo "constant PASSWORD_ARGON2I is not defined\n";
		$success = false;
	}
	if (!password_verify('password', '$argon2i$v=19$m=8,t=1,p=1$RWxaRlZ0d1FTa3RSY1c1OQ$c7a/rJlPgvH9ItPi74UGuh0tdCBhpdDF7b/nA3QweX8')) {
		echo "Failed check test vector\n";
		$success = false;
	}
}
var_dump($success);
