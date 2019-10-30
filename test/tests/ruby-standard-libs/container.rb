# https://stdgems.org/ (https://github.com/janlelis/stdgems)
stdlib = [
	'abbrev',
	'base64',
	'benchmark',
	'bigdecimal',
	'cgi',
	'cmath',
	'coverage',
	'csv',
	'date',
	'dbm',
	'delegate',
	'digest',
	'drb',
	'e2mmap',
	'erb',
	'etc',
	'expect',
	'fcntl',
	'fiddle',
	'fileutils',
	'find',
	'forwardable',
	'gdbm',
	'getoptlong',
	'io/console',
	'io/nonblock',
	'io/wait',
	'ipaddr',
	'irb',
	'json',
	'logger',
	'mathn',
	'matrix',
	'mkmf',
	'monitor',
	'mutex_m',
	'net/ftp',
	'net/http',
	'net/imap',
	'net/pop',
	'net/smtp',
	'net/telnet',
	'nkf',
	'objspace',
	'observer',
	'open-uri',
	'open3',
	'openssl',
	'optparse',
	'ostruct',
	'pathname',
	'pp',
	'prettyprint',
	'prime',
	#'profile', # prints all sorts of info to stderr, not easy to test right now
	'profiler',
	'pstore',
	'psych',
	'pty',
	'rake',
	'rdoc',
	'readline',
	'resolv',
	'resolv-replace',
	'ripper',
	'rss',
	'rubygems',
	'scanf',
	'sdbm',
	'securerandom',
	'set',
	'shell',
	'shellwords',
	'singleton',
	'socket',
	'stringio',
	'strscan',
	'sync',
	'syslog',
	'tempfile',
	'thread',
	'thwait',
	'time',
	'timeout',
	'tmpdir',
	'tracer',
	'tsort',
	'un',
	'uri',
	'weakref',
	'webrick',
	'xmlrpc/client',
	'xmlrpc/server',
	'yaml',
	'zlib',
]

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
	# these libraries don't work or don't exist on JRuby ATM
	stdlib.delete('dbm')
	stdlib.delete('gdbm')
	stdlib.delete('mkmf')
	stdlib.delete('objspace')
	stdlib.delete('sdbm')
end

require 'rubygems/version'
rubyVersion = Gem::Version.create(RUBY_VERSION)
if rubyVersion >= Gem::Version.create('2.5')
	# https://bugs.ruby-lang.org/issues/13335
	stdlib.delete('mathn')
end
if rubyVersion >= Gem::Version.create('2.7')
	# https://bugs.ruby-lang.org/issues/15652
	# "Removed from standard library. No one maintains it"
	stdlib.delete('profiler')
	# https://bugs.ruby-lang.org/issues/16170
	# "removing some of the unmaintained libraries"
	stdlib.delete('cmath')
	stdlib.delete('e2mmap')
	stdlib.delete('scanf')
	stdlib.delete('shell')
	stdlib.delete('sync')
	stdlib.delete('thwait')
	stdlib.delete('tracer')
end

result = 'ok'
stdlib.each do |lib|
	#puts "Testing #{lib}"
	begin
		require lib
	rescue Exception => e
		result = 'failure'
		STDERR.puts "\n\nrequire '#{lib}' failed: #{e.message}\n"
		STDERR.puts e.backtrace.join("\n")
		STDERR.puts "\n"
	end
end

exit(1) unless result == 'ok'

puts result
