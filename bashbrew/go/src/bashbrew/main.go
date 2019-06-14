package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/codegangsta/cli"

	"github.com/docker-library/go-dockerlibrary/manifest"
)

// TODO somewhere, ensure that the Docker engine we're talking to is API version 1.22+ (Docker 1.10+)
//   docker version --format '{{.Server.APIVersion}}'

var (
	configPath  string
	flagsConfig *FlagsConfig

	defaultLibrary string
	defaultCache   string

	arch                 string
	namespace            string
	constraints          []string
	exclusiveConstraints bool

	archNamespaces map[string]string

	debugFlag  = false
	noSortFlag = false

	// separated so that FlagsConfig.ApplyTo can access them
	flagEnvVars = map[string]string{
		"debug":     "BASHBREW_DEBUG",
		"arch":      "BASHBREW_ARCH",
		"namespace": "BASHBREW_NAMESPACE",
		"config":    "BASHBREW_CONFIG",
		"library":   "BASHBREW_LIBRARY",
		"cache":     "BASHBREW_CACHE",
		"pull":      "BASHBREW_PULL",

		"constraint":     "BASHBREW_CONSTRAINTS",
		"arch-namespace": "BASHBREW_ARCH_NAMESPACES",
	}
)

func initDefaultConfigPath() string {
	xdgConfig := os.Getenv("XDG_CONFIG_HOME")
	if xdgConfig == "" {
		xdgConfig = filepath.Join(os.Getenv("HOME"), ".config")
	}
	return filepath.Join(xdgConfig, "bashbrew")
}

func initDefaultCachePath() string {
	xdgCache := os.Getenv("XDG_CACHE_HOME")
	if xdgCache == "" {
		xdgCache = filepath.Join(os.Getenv("HOME"), ".cache")
	}
	return filepath.Join(xdgCache, "bashbrew")
}

func main() {
	app := cli.NewApp()
	app.Name = "bashbrew"
	app.Usage = "canonical build tool for the official images"
	app.Version = "dev"
	app.HideVersion = true
	app.EnableBashCompletion = true

	// TODO add "Description" to app and commands (for longer-form description of their functionality)

	// add "-?" to HelpFlag
	cli.HelpFlag = cli.BoolFlag{
		Name:  "help, h, ?",
		Usage: "show help",
	}

	app.Flags = []cli.Flag{
		cli.BoolFlag{
			Name:   "debug",
			EnvVar: flagEnvVars["debug"],
			Usage:  `enable more output (esp. all "docker build" output instead of only output on failure)`,
		},
		cli.BoolFlag{
			Name:  "no-sort",
			Usage: "do not apply any sorting, even via --build-order",
		},

		cli.StringFlag{
			Name:   "arch",
			Value:  manifest.DefaultArchitecture,
			EnvVar: flagEnvVars["arch"],
			Usage:  "the current platform architecture",
		},
		cli.StringFlag{
			Name:   "namespace",
			EnvVar: flagEnvVars["namespace"],
			Usage:  "a repo namespace to act upon/in",
		},
		cli.StringSliceFlag{
			Name:   "constraint",
			EnvVar: flagEnvVars["constraint"],
			Usage:  "build constraints (see Constraints in Manifest2822Entry)",
		},
		cli.BoolFlag{
			Name:  "exclusive-constraints",
			Usage: "skip entries which do not have Constraints",
		},

		cli.StringSliceFlag{
			Name:   "arch-namespace",
			EnvVar: flagEnvVars["arch-namespace"],
			Usage:  `architecture to push namespace mappings for creating indexes/manifest lists ("arch=namespace" ala "s390x=tianons390x")`,
		},

		cli.StringFlag{
			Name:   "config",
			Value:  initDefaultConfigPath(),
			EnvVar: flagEnvVars["config"],
			Usage:  `where default "flags" configuration can be overridden more persistently`,
		},
		cli.StringFlag{
			Name:   "library",
			Value:  filepath.Join(os.Getenv("HOME"), "docker", "official-images", "library"),
			EnvVar: flagEnvVars["library"],
			Usage:  "where the bodies are buried",
		},
		cli.StringFlag{
			Name:   "cache",
			Value:  initDefaultCachePath(),
			EnvVar: flagEnvVars["cache"],
			Usage:  "where the git wizardry is stashed",
		},
	}

	app.Before = func(c *cli.Context) error {
		var err error

		configPath, err = filepath.Abs(c.String("config"))
		if err != nil {
			return err
		}

		flagsConfig, err = ParseFlagsConfigFile(filepath.Join(configPath, "flags"))
		if err != nil && !os.IsNotExist(err) {
			return err
		}

		return nil
	}

	subcommandBeforeFactory := func(cmd string) cli.BeforeFunc {
		return func(c *cli.Context) error {
			err := flagsConfig.ApplyTo(cmd, c)
			if err != nil {
				return err
			}

			debugFlag = c.GlobalBool("debug")
			noSortFlag = c.GlobalBool("no-sort")

			arch = c.GlobalString("arch")
			namespace = c.GlobalString("namespace")
			constraints = c.GlobalStringSlice("constraint")
			exclusiveConstraints = c.GlobalBool("exclusive-constraints")

			archNamespaces = map[string]string{}
			for _, archMapping := range c.GlobalStringSlice("arch-namespace") {
				splitArchMapping := strings.SplitN(archMapping, "=", 2)
				splitArch, splitNamespace := strings.TrimSpace(splitArchMapping[0]), strings.TrimSpace(splitArchMapping[1])
				archNamespaces[splitArch] = splitNamespace
			}

			defaultLibrary, err = filepath.Abs(c.GlobalString("library"))
			if err != nil {
				return err
			}
			defaultCache, err = filepath.Abs(c.GlobalString("cache"))
			if err != nil {
				return err
			}

			return nil
		}
	}

	// define a few useful flags so their usage, etc can be consistent
	commonFlags := map[string]cli.Flag{
		"all": cli.BoolFlag{
			Name:  "all",
			Usage: "act upon all repos listed in --library",
		},
		"uniq": cli.BoolFlag{
			Name:  "uniq, unique",
			Usage: "only act upon the first tag of each entry",
		},
		"apply-constraints": cli.BoolFlag{
			Name:  "apply-constraints",
			Usage: "apply Constraints as if repos were building",
		},
		"depth": cli.IntFlag{
			Name:  "depth",
			Value: 0,
			Usage: "maximum number of levels to traverse (0 for unlimited)",
		},
		"dry-run": cli.BoolFlag{
			Name:  "dry-run",
			Usage: "do everything except the final action (for testing whether actions will be performed)",
		},
		"force": cli.BoolFlag{
			Name:  "force",
			Usage: "always push (skip the clever Hub API lookups that no-op things sooner if a push doesn't seem necessary)",
		},
		"target-namespace": cli.StringFlag{
			Name:  "target-namespace",
			Usage: `target namespace to act into ("docker tag namespace/repo:tag target-namespace/repo:tag", "docker push target-namespace/repo:tag")`,
		},
	}

	app.Commands = []cli.Command{
		{
			Name:    "list",
			Aliases: []string{"ls"},
			Usage:   "list repo:tag combinations for a given repo",
			Flags: []cli.Flag{
				commonFlags["all"],
				commonFlags["uniq"],
				commonFlags["apply-constraints"],
				cli.BoolFlag{
					Name:  "build-order",
					Usage: "sort by the order repos would need to build (topsort)",
				},
				cli.BoolFlag{
					Name:  "repos",
					Usage: `list only repos, not repo:tag (unless "repo:tag" is explicitly specified)`,
				},
			},
			Before: subcommandBeforeFactory("list"),
			Action: cmdList,
		},
		{
			Name:  "build",
			Usage: "build (and tag) repo:tag combinations for a given repo",
			Flags: []cli.Flag{
				commonFlags["all"],
				commonFlags["uniq"],
				cli.StringFlag{
					Name:   "pull",
					Value:  "missing",
					EnvVar: flagEnvVars["pull"],
					Usage:  `pull FROM before building (always, missing, never)`,
				},
				commonFlags["dry-run"],
			},
			Before: subcommandBeforeFactory("build"),
			Action: cmdBuild,
		},
		{
			Name:  "tag",
			Usage: "tag repo:tag into a namespace (especially for pushing)",
			Flags: []cli.Flag{
				commonFlags["all"],
				commonFlags["uniq"],
				commonFlags["dry-run"],
				commonFlags["target-namespace"],
			},
			Before: subcommandBeforeFactory("tag"),
			Action: cmdTag,
		},
		{
			Name:  "push",
			Usage: `push namespace/repo:tag (see also "tag")`,
			Flags: []cli.Flag{
				commonFlags["all"],
				commonFlags["uniq"],
				commonFlags["dry-run"],
				commonFlags["force"],
				commonFlags["target-namespace"],
			},
			Before: subcommandBeforeFactory("push"),
			Action: cmdPush,
		},
		{
			Name:  "put-shared",
			Usage: `update shared tags in the registry (and multi-architecture tags)`,
			Flags: []cli.Flag{
				commonFlags["all"],
				commonFlags["dry-run"],
				commonFlags["force"],
				commonFlags["target-namespace"],
				cli.BoolFlag{
					Name:  "single-arch",
					Usage: `only act on the current architecture (for pushing "amd64/hello-world:latest", for example)`,
				},
			},
			Before: subcommandBeforeFactory("put-shared"),
			Action: cmdPutShared,
		},

		{
			Name: "children",
			Aliases: []string{
				"offspring",
				"descendants",
				"progeny",
			},
			Usage: `print the repos built FROM a given repo or repo:tag`,
			Flags: []cli.Flag{
				commonFlags["apply-constraints"],
				commonFlags["depth"],
			},
			Before: subcommandBeforeFactory("children"),
			Action: cmdOffspring,

			Category: "plumbing",
		},
		{
			Name: "parents",
			Aliases: []string{
				"ancestors",
				"progenitors",
			},
			Usage: `print the repos this repo or repo:tag is FROM`,
			Flags: []cli.Flag{
				commonFlags["apply-constraints"],
				commonFlags["depth"],
			},
			Before: subcommandBeforeFactory("parents"),
			Action: cmdParents,

			Category: "plumbing",
		},
		{
			Name:  "cat",
			Usage: "print manifest contents for repo or repo:tag",
			Flags: []cli.Flag{
				commonFlags["all"],
				cli.StringFlag{
					Name:  "format, f",
					Usage: "change the `FORMAT` of the output",
					Value: DefaultCatFormat,
				},
				cli.StringFlag{
					Name:  "format-file, F",
					Usage: "use the contents of `FILE` for \"--format\"",
				},
			},
			Before: subcommandBeforeFactory("cat"),
			Action: cmdCat,

			Description: `see Go's "text/template" package (https://golang.org/pkg/text/template/) for details on the syntax expected in "--format"`,

			Category: "plumbing",
		},
		{
			Name:  "from",
			Usage: "print FROM for repo:tag",
			Flags: []cli.Flag{
				commonFlags["all"],
				commonFlags["uniq"],
				commonFlags["apply-constraints"],
			},
			Before: subcommandBeforeFactory("from"),
			Action: cmdFrom,

			Category: "plumbing",
		},
	}

	err := app.Run(os.Args)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
