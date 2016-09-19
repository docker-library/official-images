/* {{{ Copyright (c) Paul R. Tagliamonte <paultag@gmail.com>, 2015
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE. }}} */

package topsort

import (
	"errors"
)

// Network Helpers {{{

type Network struct {
	nodes map[string]*Node
	order []string
}

func NewNetwork() *Network {
	return &Network{
		nodes: map[string]*Node{},
		order: []string{},
	}
}

func (tn *Network) Sort() ([]*Node, error) {
	nodes := make([]*Node, 0)
	for _, key := range tn.order {
		nodes = append(nodes, tn.nodes[key])
	}
	return sortNodes(nodes)
}

func (tn *Network) Get(name string) *Node {
	return tn.nodes[name]
}

func (tn *Network) AddNode(name string, value interface{}) *Node {
	node := Node{
		Name:          name,
		Value:         value,
		InboundEdges:  make([]*Node, 0),
		OutboundEdges: make([]*Node, 0),
		Marked:        false,
	}

	if _, ok := tn.nodes[name]; !ok {
		tn.order = append(tn.order, name)
	}
	tn.nodes[name] = &node
	return &node
}

// }}}

// Node Helpers {{{

type Node struct {
	Name          string
	Value         interface{}
	OutboundEdges []*Node
	InboundEdges  []*Node
	Marked        bool
}

func (node *Node) IsCanidate() bool {
	for _, edge := range node.InboundEdges {
		/* for each node, let's check if they're all marked */
		if !edge.Marked {
			return false
		}
	}
	return true
}

func (tn *Network) AddEdge(from string, to string) error {
	fromNode := tn.Get(from)
	toNode := tn.Get(to)

	if fromNode == nil || toNode == nil {
		return errors.New("Either the root or target node doesn't exist")
	}

	toNode.InboundEdges = append(toNode.InboundEdges, fromNode)
	fromNode.OutboundEdges = append(fromNode.OutboundEdges, toNode)

	return nil
}

func (tn *Network) AddEdgeIfExists(from string, to string) {
	tn.AddEdge(from, to)
}

// }}}

// Sort Helpers {{{

func sortSingleNodes(nodes []*Node) ([]*Node, error) {
	ret := make([]*Node, 0)
	hasUnprunedNodes := false

	for _, node := range nodes {
		if node.Marked {
			continue /* Already output. */
		}

		hasUnprunedNodes = true

		/* Otherwise, let's see if we can prune it */
		if node.IsCanidate() {
			/* So, it has no deps and hasn't been marked; let's mark and
			 * output */
			node.Marked = true
			ret = append(ret, node)
		}
	}

	if hasUnprunedNodes && len(ret) == 0 {
		return nil, errors.New("Cycle detected :(")
	}

	return ret, nil
}

func sortNodes(nodes []*Node) (ret []*Node, err error) {
	/* Reset Marked status of nodes so they're ready to sort */
	for _, node := range nodes {
		node.Marked = false
	}
	for {
		generation, err := sortSingleNodes(nodes)
		if err != nil {
			return nil, err
		}
		if len(generation) == 0 {
			break
		}
		ret = append(ret, generation...)
	}
	return
}

// }}}

// vim: foldmethod=marker
