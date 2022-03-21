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
if rubyVersion >= Gem::Version.create('3.0')
	# https://www.ruby-lang.org/en/news/2020/09/25/ruby-3-0-0-preview1-released/
	# Removed libraries no longer part of stdlib.
	stdlib.delete('English')
	stdlib.delete('abbrev')
	stdlib.delete('base64')
	stdlib.delete('erb')
	stdlib.delete('find')
	stdlib.delete('io/nonblock')
	stdlib.delete('io/wait')
	stdlib.delete('net/ftp')
	stdlib.delete('net/http')
	stdlib.delete('net/imap')
	stdlib.delete('net/protocol')
	stdlib.delete('net/telnet')
	stdlib.delete('nkf')
	stdlib.delete('open-uri')
	stdlib.delete('optparse')
	stdlib.delete('resolv')
	stdlib.delete('resolv-replace')
	stdlib.delete('rexml')
	stdlib.delete('rinda')
	stdlib.delete('rss')
	stdlib.delete('securerandom')
	stdlib.delete('set')
	stdlib.delete('shellwords')
	stdlib.delete('tempfile')
	stdlib.delete('time')
	stdlib.delete('tmpdir')
	stdlib.delete('tsort')
	stdlib.delete('weakref')
	stdlib.delete('xmlrpc/client')
	stdlib.delete('xmlrpc/server')
	# https://github.com/ruby/ruby/blob/v3_0_0_preview1/NEWS.md#stdlib-compatibility-issues
	# https://bugs.ruby-lang.org/issues/8446
	stdlib.delete('sdbm')
	# https://github.com/ruby/ruby/blob/v3_0_0_rc1/NEWS.md#stdlib-compatibility-issues
	# https://bugs.ruby-lang.org/issues/17303
	stdlib.delete('webrick')
end
if rubyVersion >= Gem::Version.create('3.1')
	# https://github.com/ruby/ruby/pull/4525
	stdlib.delete('dbm')
	# https://github.com/ruby/ruby/pull/4526
	stdlib.delete('gdbm')
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
