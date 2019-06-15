package main

import (
	"fmt"

	"github.com/codegangsta/cli"
	"pault.ag/go/topsort"
)

func cmdOffspring(c *cli.Context) error {
	return cmdFamily(false, c)
}

func cmdParents(c *cli.Context) error {
	return cmdFamily(true, c)
}

type topsortDepthNodes struct {
	depth int
	nodes []*topsort.Node
}

func cmdFamily(parents bool, c *cli.Context) error {
	depsRepos, err := repos(c.Bool("all"), c.Args()...)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed gathering repo list`), err)
	}

	uniq := c.Bool("uniq")
	applyConstraints := c.Bool("apply-constraints")
	depth := c.Int("depth")

	allRepos, err := repos(true)
	if err != nil {
		return cli.NewMultiError(fmt.Errorf(`failed gathering ALL repos list`), err)
	}

	// create network (all repos)
	network := topsort.NewNetwork()

	// add nodes
	for _, repo := range allRepos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		for _, entry := range r.Entries() {
			if applyConstraints && r.SkipConstraints(entry) {
				continue
			}

			for _, tag := range r.Tags(namespace, false, entry) {
				network.AddNode(tag, entry)
			}
		}
	}

	// add edges
	for _, repo := range allRepos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}
		for _, entry := range r.Entries() {
			if applyConstraints && r.SkipConstraints(entry) {
				continue
			}

			entryArches := []string{arch}
			if !applyConstraints {
				entryArches = entry.Architectures
			}

			for _, entryArch := range entryArches {
				froms, err := r.ArchDockerFroms(entryArch, entry)
				if err != nil {
					return cli.NewMultiError(fmt.Errorf(`failed fetching/scraping FROM for %q (tags %q, arch %q)`, r.RepoName, entry.TagsString(), entryArch), err)
				}
				for _, from := range froms {
					for _, tag := range r.Tags(namespace, false, entry) {
						network.AddEdge(from, tag)
					}
				}
			}
		}
	}

	// now the real work
	seen := map[*topsort.Node]bool{}
	for _, repo := range depsRepos {
		r, err := fetch(repo)
		if err != nil {
			return cli.NewMultiError(fmt.Errorf(`failed fetching repo %q`, repo), err)
		}

		for _, entry := range r.Entries() {
			if applyConstraints && r.SkipConstraints(entry) {
				continue
			}

			for _, tag := range r.Tags(namespace, uniq, entry) {
				nodes := []topsortDepthNodes{}
				if parents {
					nodes = append(nodes, topsortDepthNodes{
						depth: 1,
						nodes: network.Get(tag).InboundEdges,
					})
				} else {
					nodes = append(nodes, topsortDepthNodes{
						depth: 1,
						nodes: network.Get(tag).OutboundEdges,
					})
				}
				for len(nodes) > 0 {
					depthNodes := nodes[0]
					nodes = nodes[1:]
					if depth > 0 && depthNodes.depth > depth {
						continue
					}
					for _, node := range depthNodes.nodes {
						if seen[node] {
							continue
						}
						seen[node] = true
						fmt.Printf("%s\n", node.Name)
						if parents {
							nodes = append(nodes, topsortDepthNodes{
								depth: depthNodes.depth + 1,
								nodes: node.InboundEdges,
							})
						} else {
							nodes = append(nodes, topsortDepthNodes{
								depth: depthNodes.depth + 1,
								nodes: node.OutboundEdges,
							})
						}
					}
				}
			}
		}
	}

	return nil
}
