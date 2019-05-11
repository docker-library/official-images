#!/usr/bin/env perl
use Mojo::Base -strict, -signatures;

# this is a replacement for "bashbrew put-shared" (without "--single-arch") to combine many architecture-specific repositories into manifest lists in a separate repository
# for example, combining amd64/bash:latest, arm32v5/bash:latest, ..., s390x/bash:latest into a single library/bash:latest manifest list
# (in a more efficient way than manifest-tool can do generically such that we can reasonably do 3700+ no-op tag pushes individually in ~9 minutes)

use Digest::SHA;
use Mojo::Promise;
use Mojo::UserAgent;
use Mojo::Util;

my $publicProxy = $ENV{DOCKERHUB_PUBLIC_PROXY} || die 'missing DOCKERHUB_PUBLIC_PROXY env (https://github.com/tianon/dockerhub-public-proxy)';
my $dryRun = ($ARGV[0] || '') eq '--dry-run';
shift @ARGV if $dryRun;

my $ua = Mojo::UserAgent->new->max_redirects(10)->connect_timeout(120)->inactivity_timeout(120);
$ua->transactor->name(join ' ',
	# https://github.com/docker/docker/blob/v1.11.2/dockerversion/useragent.go#L13-L34
	'docker/1.11.2',
	'go/1.6.2',
	'git-commit/v1.11.2',
	'kernel/4.4.11',
	'os/linux',
	'arch/amd64',
	# BOGUS USER AGENTS FOR THE BOGUS USER AGENT THRONE
);

sub ua_retry_simple_req_p ($method, $url, $tries = 10) {
	--$tries;
	my $lastTry = $tries < 1;

	my $methodP = lc($method) . '_p';
	my $prom = $ua->$methodP($url);
	if (!$lastTry) {
		$prom = $prom->then(sub ($tx) {
			return $tx if !$tx->error || $tx->res->code == 404 || $tx->res->code == 401;
			return ua_retry_simple_req_p($method, $url, $tries);
		}, sub {
			return ua_retry_simple_req_p($method, $url, $tries);
		});
	}
	return $prom;
}

sub split_image_name ($image) {
	if ($image =~ m{
		^
		(?: ([^/:]+) / )? # optional namespace
		([^/:]+)          # image name
		(?: : ([^/:]+) )? # optional tag
		$
	}x) {
		my ($namespace, $name, $tag) = (
			$1 // 'library', # namespace
			$2,              # image name
			$3 // 'latest',  # tag
		);
		return ($namespace, $name, $tag);
	}
	die "unrecognized image name format in: $image";
}

sub arch_to_platform ($arch) {
	if ($arch =~ m{
		^
		(?: ([^-]+) - )? # optional "os" prefix ("windows-", etc)
		([^-]+?) # "architecture" bit ("arm64", "s390x", etc)
		(v[0-9]+)? # optional "variant" suffix ("v7", "v6", etc)
		$
	}x) {
		return (
			os => $1 // 'linux',
			architecture => (
				$2 eq 'i386'
				? '386'
				: (
					$2 eq 'arm32'
					? 'arm'
					: $2
				)
			),
			($3 ? (variant => $3) : ()),
		);
	}
	die "unrecognized architecture format in: $arch";
}

# TODO make this promise-based and non-blocking?
# https://github.com/jberger/Mojolicious-Plugin-TailLog/blob/master/lib/Mojolicious/Plugin/TailLog.pm#L16-L22
# https://metacpan.org/pod/Capture::Tiny
# https://metacpan.org/pod/Mojo::IOLoop#subprocess
# https://metacpan.org/pod/IO::Async::Process
sub bashbrew (@) {
	open my $fh, '-|', 'bashbrew', @_ or die "failed to run 'bashbrew': $!";
	local $/;
	my $output = <$fh>;
	close $fh or die "failed to close 'bashbrew'";
	chomp $output;
	return $output;
}

sub get_manifest_p ($org, $repo, $ref, $tries = 3) {
	--$tries;
	my $lastTry = $tries < 1;

	state %cache;
	if ($ref =~ m!^sha256:! && $cache{$ref}) {
		return Mojo::Promise->resolve($cache{$ref});
	}

	return ua_retry_simple_req_p(GET => "$publicProxy/v2/$org/$repo/manifests/$ref")->then(sub ($tx) {
		return if $tx->res->code == 404 || $tx->res->code == 401;

		if (!$lastTry && $tx->res->code != 200) {
			return get_manifest_p($org, $repo, $ref, $tries);
		}
		die "unexpected exit code fetching '$org/$repo:$ref': " . $tx->res->code unless $tx->res->code == 200;

		my $digest = $tx->res->headers->header('docker-content-digest') or die "'$org/$repo:$ref' is missing 'docker-content-digest' header";
		die "malformed 'docker-content-digest' header in '$org/$repo:$ref': '$digest'" unless $digest =~ m!^sha256:!;

		my $manifest = $tx->res->json or die "'$org/$repo:$ref' has bad or missing JSON";
		my $size = int($tx->res->headers->content_length);
		my $verbatim = $tx->res->body;

		return $cache{$digest} = {
			digest => $digest,
			manifest => $manifest,
			size => $size,
			verbatim => $verbatim,

			mediaType => (
				$manifest->{schemaVersion} == 1
				? 'application/vnd.docker.distribution.manifest.v1+json'
				: (
					$manifest->{schemaVersion} == 2
					? $manifest->{mediaType}
					: die "unknown schemaVersion for '$org/$repo' at '$ref'"
				)
			),
		};
	});
}

sub get_blob_p ($org, $repo, $ref, $tries = 3) {
	die "unexpected blob reference for '$org/$repo': '$ref'" unless $ref =~ m!^sha256:!;

	--$tries;
	my $lastTry = $tries < 1;

	state %cache;
	return Mojo::Promise->resolve($cache{$ref}) if $cache{$ref};

	return ua_retry_simple_req_p(GET => "$publicProxy/v2/$org/$repo/blobs/$ref")->then(sub ($tx) {
		return if $tx->res->code == 404;

		if (!$lastTry && $tx->res->code != 200) {
			return get_blob_p($org, $repo, $ref, $tries);
		}
		die "unexpected exit code fetching blob from '$org/$repo:$ref'': " . $tx->res->code unless $tx->res->code == 200;

		return $cache{$ref} = $tx->res->json;
	});
}

sub head_manifest_p ($org, $repo, $ref) {
	die "unexpected manifest reference for HEAD '$org/$repo': '$ref'" unless $ref =~ m!^sha256:!;

	my $cacheKey = "$org/$repo:$ref";
	state %cache;
	return Mojo::Promise->resolve($cache{$cacheKey}) if $cache{$cacheKey};

	return ua_retry_simple_req_p(HEAD => "$publicProxy/v2/$org/$repo/manifests/$ref")->then(sub ($tx) {
		return 0 if $tx->res->code == 404 || $tx->res->code == 401;
		die "unexpected exit code HEADing manifest '$cacheKey': " . $tx->res->code unless $tx->res->code == 200;
		return $cache{$cacheKey} = 1;
	});
}

sub head_blob_p ($org, $repo, $ref) {
	die "unexpected blob reference for HEAD '$org/$repo': '$ref'" unless $ref =~ m!^sha256:!;

	my $cacheKey = "$org/$repo:$ref";
	state %cache;
	return Mojo::Promise->resolve($cache{$cacheKey}) if $cache{$cacheKey};

	return ua_retry_simple_req_p(HEAD => "$publicProxy/v2/$org/$repo/blobs/$ref")->then(sub ($tx) {
		return 0 if $tx->res->code == 404 || $tx->res->code == 401;
		die "unexpected exit code HEADing blob '$cacheKey': " . $tx->res->code unless $tx->res->code == 200;
		return $cache{$cacheKey} = 1;
	});
}

# get list of manifest list items and necessary blobs for a particular architecture
sub get_arch_p ($targetNamespace, $arch, $archNamespace, $repo, $tag) {
	return get_manifest_p($archNamespace, $repo, $tag)->then(sub ($manifestData = undef) {
		return unless $manifestData;
		my ($digest, $manifest, $size) = ($manifestData->{digest}, $manifestData->{manifest}, $manifestData->{size});

		my $mediaType = $manifestData->{mediaType};
		if ($mediaType eq 'application/vnd.docker.distribution.manifest.list.v2+json') {
			# jackpot -- if it's already a manifest list, the hard work is done!
			return ($archNamespace, $manifest->{manifests});
		}
		if ($mediaType eq 'application/vnd.docker.distribution.manifest.v1+json' || $mediaType eq 'application/vnd.docker.distribution.manifest.v2+json') {
			my $manifestListItem = {
				mediaType => $mediaType,
				size => $size,
				digest => $digest,
				platform => {
					arch_to_platform($arch),
					($manifest->{'os.version'} ? ('os.version' => $manifest->{'os.version'}) : ()),
				},
			};
			if ($manifestListItem->{platform}{os} eq 'windows' && !$manifestListItem->{platform}{'os.version'} && $mediaType eq 'application/vnd.docker.distribution.manifest.v2+json') {
				# if we're on Windows, we need to make an effort to fetch the "os.version" value from the config for the platform object
				return get_blob_p($archNamespace, $repo, $manifest->{config}{digest})->then(sub ($config = undef) {
					if ($config && $config->{'os.version'}) {
						$manifestListItem->{platform}{'os.version'} = $config->{'os.version'};
					}
					return ($archNamespace, [ $manifestListItem ]);
				});
			}
			else {
				return ($archNamespace, [ $manifestListItem ]);
			}
		}

		die "unknown mediaType '$mediaType' for '$archNamespace/$repo:$tag'";
	});
}

sub needed_artifacts_p ($targetNamespace, $sourceNamespace, $repo, $manifestDigest) {
	return head_manifest_p($targetNamespace, $repo, $manifestDigest)->then(sub ($exists) {
		return if $exists;

		return get_manifest_p($sourceNamespace, $repo, $manifestDigest)->then(sub ($manifestData = undef) {
			return unless $manifestData;

			my $manifest = $manifestData->{manifest};
			my $schemaVersion = $manifest->{schemaVersion};
			my @blobs;
			if ($schemaVersion == 1) {
				push @blobs, map { $_->{blobSum} } @{ $manifest->{fsLayers} };
			}
			elsif ($schemaVersion == 2) {
				die "this should never happen: $manifest->{mediaType}" unless $manifest->{mediaType} eq 'application/vnd.docker.distribution.manifest.v2+json'; # sanity check
				push @blobs, $manifest->{config}{digest}, map { $_->{urls} ? () : $_->{digest} } @{ $manifest->{layers} };
			}
			else {
				die "this should never happen: $schemaVersion"; # sanity check
			}

			return Mojo::Promise->all(
				Mojo::Promise->resolve([ $sourceNamespace, $repo, 'manifest', $manifestDigest ]),
				Mojo::Promise->map({ concurrency => 3 }, sub ($blob) {
					return head_blob_p($targetNamespace, $repo, $blob)->then(sub ($exists) {
						return if $exists;
						return $sourceNamespace, $repo, 'blob', $blob;
					});
				}, @blobs),
			)->then(sub { map { @$_ } @_ });
		});
	});
}

sub get_dockerhub_creds {
	die 'missing DOCKER_CONFIG or HOME environment variable' unless $ENV{DOCKER_CONFIG} or $ENV{HOME};
	my $config = Mojo::File->new(($ENV{DOCKER_CONFIG} || ($ENV{HOME} . '/.docker')) . '/config.json')->slurp;
	die 'missing or empty ".docker/config.json" file' unless $config;
	my $json = Mojo::JSON::decode_json($config);
	die 'invalid ".docker/config.json" file' unless $json && $json->{auths};
	for my $registry (keys %{ $json->{auths} }) {
		my $auth = $json->{auths}{$registry}{auth};
		next unless $auth;
		if ($registry eq 'https://index.docker.io/v1/' || $registry eq 'index.docker.io') {
			$auth = Mojo::Util::b64_decode($auth);
			return $auth if $auth && $auth =~ m!:!;
		}
	}
	die 'failed to find credentials for Docker Hub in ".docker/config.json" file';
}

sub authenticated_registry_req_p ($method, $repos, $url, $contentType = undef, $payload = undef, $tries = 10) {
	--$tries;
	my $lastTry = $tries < 1;

	my %headers = ($contentType ? ('Content-Type' => $contentType) : ());

	state %tokens;
	if (my $token = $tokens{$repos}) {
		$headers{Authorization} = "Bearer $token";
	}

	my $methodP = lc($method) . '_p';
	my $fullUrl = "https://registry-1.docker.io/v2/$url";
	my $prom = $ua->$methodP($fullUrl, \%headers, ($payload ? $payload : ()));
	if (!$lastTry) {
		$prom = $prom->then(sub ($tx) {
			if (!$lastTry && $tx->res->code == 401) {
				# "Unauthorized" -- we must need to go fetch a token for this registry request (so let's go do that, then retry the original registry request)
				my $auth = $tx->res->headers->www_authenticate;
				die "unexpected WWW-Authenticate header ('$url'): $auth" unless $auth =~ m{ ^ Bearer \s+ (\S.*) $ }x;
				my $realm = $1;
				my $authUrl = Mojo::URL->new;
				while ($realm =~ m{
					# key="val",
					([^=]+)
					=
					"([^"]+)"
					,?
				}xg) {
					my ($key, $val) = ($1, $2);
					next if $key eq 'error' and $val eq 'invalid_token'; # just ignore the error if it's "invalid_token" because it likely means our token expired mid-push so we just need to renew
					die "WWW-Authenticate header error ('$url'): $val ($auth)" if $key eq 'error';
					if ($key eq 'realm') {
						$authUrl->base(Mojo::URL->new($val));
					}
					else {
						$authUrl->query->append($key => $_) for split / /, $val; # Docker's auth server expects "scope=xxx&scope=yyy" instead of "scope=xxx%20yyy"
					}
				}
				$authUrl = $authUrl->to_abs;
				say {*STDERR} "Note: grabbing auth token from $authUrl (for $fullUrl; $tries tries remain)";
				my $dockerhubCreds = get_dockerhub_creds();
				return ua_retry_simple_req_p(GET => $authUrl->userinfo($dockerhubCreds)->to_unsafe_string)->then(sub ($tx) {
					if (my $error = $tx->error) {
						die "registry authentication error ('$url'): " . ($error->{code} ? $error->{code} . ' -- ' : '') . $error->{message};
					}

					$tokens{$repos} = $tx->res->json->{token};
					return authenticated_registry_req_p($method, $repos, $url, $contentType, $payload, $tries);
				});
			}

			if (!$lastTry && $tx->res->code != 200) {
				return authenticated_registry_req_p($method, $repos, $url, $contentType, $payload, $tries);
			}

			if (my $error = $tx->error) {
				$tx->req->headers->authorization('REDATCTED') if $tx->req->headers->authorization;
				die "registry request error ('$url'): " . ($error->{code} ? $error->{code} . ' -- ' : '') . $error->{message} . "\n\nREQUEST:\n" . $tx->req->headers->to_string . "\n\n" . $tx->req->body . "\n\nRESPONSE:\n" . $tx->res->to_string . "\n";
			}

			return $tx;
		}, sub {
			return authenticated_registry_req_p($method, $repos, $url, $contentType, $payload, $tries);
		});
	}
	return $prom;
}

Mojo::Promise->map({ concurrency => 8 }, sub ($img) {
	my ($org, $repo, $tag) = split_image_name($img);

	die "image '$img' is missing explict namespace -- bailing to avoid accidental push to '$org'" unless $img =~ m!/!;

	my @tags = (
		$img =~ m/:/
		? ( "$repo:$tag" )
		: ( List::Util::uniq sort split /\n/, bashbrew('list', $repo) )
	);

	return Mojo::Promise->map({ concurrency => 1 }, sub ($repoTag) {
		my (undef, $repo, $tag) = split_image_name($repoTag);

		my @arches = List::Util::uniq sort split /\n/, bashbrew('cat', '--format', '{{ range .Entries }}{{ range .Architectures }}{{ . }}={{ archNamespace . }}{{ "\n" }}{{ end }}{{ end }}', "$repo:$tag");

		return Mojo::Promise->map({ concurrency => 1 }, sub ($archData) {
			my ($arch, $archNamespace) = split /=/, $archData;
			return get_arch_p($org, $arch, $archNamespace, $repo, $tag);
		}, @arches)->then(sub (@archResponses) {
			my @manifestListItems;
			my @neededArtifactPromises;
			for my $archResponse (@archResponses) {
				next unless @$archResponse;
				my ($archNamespace, $manifestListItems) = @$archResponse;
				push @manifestListItems, @$manifestListItems;
				push @neededArtifactPromises, map { my $digest = $_->{digest}; sub { needed_artifacts_p($org, $archNamespace, $repo, $digest) } } @$manifestListItems;
			}

			my $manifestList = {
				schemaVersion => 2,
				mediaType => 'application/vnd.docker.distribution.manifest.list.v2+json',
				manifests => \@manifestListItems,
			};
			my $manifestListJson = Mojo::JSON::encode_json($manifestList);
			my $manifestListDigest = 'sha256:' . Digest::SHA::sha256_hex($manifestListJson);

			return head_manifest_p($org, $repo, $manifestListDigest)->then(sub ($exists) {
				# if we already have the manifest we're planning to push in the namespace where we plan to push it, we can skip all blob mounts! \m/
				return if $exists;
				# (we can also skip if we're in "dry run" mode since we only care about the final manifest matching in that case)
				return if $dryRun;

				return (
					@neededArtifactPromises
					? Mojo::Promise->map({ concurrency => 1 }, sub { $_->() }, @neededArtifactPromises)
					: Mojo::Promise->resolve
				)->then(sub (@neededArtifacts) {
					@neededArtifacts = map { @$_ } @neededArtifacts;
					# now "@neededArtifacts" is a list of tuples of the format [ sourceNamespace, sourceRepo, type, digest ], ready for cross-repo mounting / PUTing (where type is "blob" or "manifest")
					my @mountBlobPromises;
					my @putManifestPromises;
					for my $neededArtifact (@neededArtifacts) {
						next unless @$neededArtifact;
						my ($sourceNamespace, $sourceRepo, $type, $digest) = @$neededArtifact;
						if ($type eq 'blob') {
							# https://docs.docker.com/registry/spec/api/#mount-blob
							push @mountBlobPromises, sub { authenticated_registry_req_p(POST => "$org/$repo:push,$sourceNamespace/$sourceRepo:pull" => "$org/$repo/blobs/uploads/?mount=$digest&from=$sourceNamespace/$sourceRepo") };
						}
						elsif ($type eq 'manifest') {
							push @putManifestPromises, sub { get_manifest_p($sourceNamespace, $sourceRepo, $digest)->then(sub ($manifestData = undef) {
								return unless $manifestData;
								return authenticated_registry_req_p(PUT => "$org/$repo:push" => "$org/$repo/manifests/$digest" => $manifestData->{mediaType} => $manifestData->{verbatim});
							}) };
						}
						else {
							die "this should never happen: $type"; # sanity check
						}
					}

					# mount any necessary blobs
					return (
						@mountBlobPromises
						? Mojo::Promise->map({ concurrency => 1 }, sub { $_->() }, @mountBlobPromises)
						: Mojo::Promise->resolve
					)->then(sub {
						# ... *then* push any missing image manifests (because they'll fail to push if the blobs aren't pushed first)
						if (@putManifestPromises) {
							return Mojo::Promise->map({ concurrency => 1 }, sub { $_->() }, @putManifestPromises);
						}
						return;
					});
				});
			})->then(sub {
				# let's do one final check of the tag we're pushing to see if it's already the manifest we expect it to be (to avoid making literally every image constantly "Updated a few seconds ago" all the time)
				return get_manifest_p($org, $repo, $tag)->then(sub ($manifestData = undef) {
					if ($manifestData && $manifestData->{digest} eq $manifestListDigest) {
						say "Skipping $org/$repo:$tag ($manifestListDigest)" unless $dryRun; # if we're in "dry run" mode, we need clean output
						return;
					}

					if ($dryRun) {
						say "Would push $org/$repo:$tag ($manifestListDigest)";
						return;
					}

					# finally, all necessary blobs and manifests are pushed, we've verified that we do in fact need to push this manifest, so we should be golden to push it!
					return authenticated_registry_req_p(PUT => "$org/$repo:push" => "$org/$repo/manifests/$tag" => $manifestList->{mediaType} => $manifestListJson)->then(sub ($tx) {
						my $digest = $tx->res->headers->header('Docker-Content-Digest');
						say "Pushed $org/$repo:$tag ($digest)";
						say {*STDERR} "WARNING: expected '$manifestListDigest', got '$digest' (for '$org/$repo:$tag')" unless $manifestListDigest eq $digest;
					});
				});
			});
		});
	}, @tags);
}, @ARGV)->catch(sub {
	say {*STDERR} "ERROR: $_" for @_;
	exit scalar @_;
})->wait;
