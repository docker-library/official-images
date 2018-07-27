# https://github.com/docker-library/julia/pull/6
download("https://google.com")

# https://github.com/docker-library/julia/pull/9
if VERSION.major > 0 || (VERSION.major == 0 && VERSION.minor >= 7)
	# https://github.com/docker-library/julia/pull/21
	# https://github.com/JuliaLang/julia/tree/v0.7.0-beta2/stdlib/Pkg
	using Pkg
end
Pkg.add("JSON")
