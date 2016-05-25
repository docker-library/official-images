package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"os"

	"github.com/codegangsta/cli"
	"github.com/docker-library/go-dockerlibrary/pkg/stripper"
	"pault.ag/go/debian/control"
)

type FlagsConfigEntry struct {
	control.Paragraph

	Commands []string `delim:"," strip:"\n\r\t "`

	Library    string
	Cache      string
	Verbose    string
	Unique     string
	Namespace  string
	BuildOrder string

	Constraints          []string `delim:"," strip:"\n\r\t "`
	ExclusiveConstraints string
	ApplyConstraints     string
}

type FlagsConfig map[string]FlagsConfigEntry

func (dst *FlagsConfigEntry) Apply(src FlagsConfigEntry) {
	if src.Library != "" {
		dst.Library = src.Library
	}
	if src.Cache != "" {
		dst.Cache = src.Cache
	}
	if src.Verbose != "" {
		dst.Verbose = src.Verbose
	}
	if src.Unique != "" {
		dst.Unique = src.Unique
	}
	if src.Namespace != "" {
		dst.Namespace = src.Namespace
	}
	if len(src.Constraints) > 0 {
		dst.Constraints = src.Constraints[:]
	}
	if src.ExclusiveConstraints != "" {
		dst.ExclusiveConstraints = src.ExclusiveConstraints
	}
	if src.ApplyConstraints != "" {
		dst.ApplyConstraints = src.ApplyConstraints
	}
}

func (config FlagsConfigEntry) Vars() map[string]map[string]interface{} {
	return map[string]map[string]interface{}{
		"global": {
			"library": config.Library,
			"cache":   config.Cache,
			"verbose": config.Verbose,

			"constraint":            config.Constraints,
			"exclusive-constraints": config.ExclusiveConstraints,
		},

		"local": {
			"uniq":        config.Unique,
			"namespace":   config.Namespace,
			"build-order": config.BuildOrder,

			"apply-constraints": config.ApplyConstraints,
		},
	}
}

func (config FlagsConfig) ApplyTo(cmd string, c *cli.Context) error {
	entry := config[""]
	if cmd != "" {
		entry.Apply(config[cmd])
	}
	vars := entry.Vars()
	if cmd == "" {
		vars["local"] = vars["global"]
		vars["global"] = nil
	}
	for key, val := range vars["global"] {
		if !c.GlobalIsSet(key) {
			switch val.(type) {
			case string:
				strVal := val.(string)
				if strVal == "" {
					continue
				}
				c.GlobalSet(key, strVal)
			case []string:
				strSlice := val.([]string)
				if len(strSlice) == 0 {
					continue
				}
				for _, valBit := range strSlice {
					c.GlobalSet(key, valBit)
				}
			default:
				return fmt.Errorf(`unknown value type %T (%s: %+v)`, val, key, val)
			}
		}
	}
	for key, val := range vars["local"] {
		if !c.IsSet(key) {
			switch val.(type) {
			case string:
				strVal := val.(string)
				if strVal == "" {
					continue
				}
				c.Set(key, strVal)
			case []string:
				strSlice := val.([]string)
				if len(strSlice) == 0 {
					continue
				}
				for _, valBit := range strSlice {
					c.Set(key, valBit)
				}
			default:
				return fmt.Errorf(`unknown value type %T (%s: %+v)`, val, key, val)
			}
		}
	}
	return nil
}

func (ce FlagsConfigEntry) String() string {
	buf := &bytes.Buffer{}
	e, err := control.NewEncoder(buf)
	if err == nil {
		err = e.Encode(&ce)
		if err == nil {
			return buf.String()
		}
	}
	return ""
}

func NewFlagsConfig() *FlagsConfig {
	return &FlagsConfig{}
}

func ParseFlagsConfigFile(file string) (*FlagsConfig, error) {
	config := NewFlagsConfig()
	return config, config.ParseFile(file)
}

func ParseFlagsConfig(in io.Reader) (*FlagsConfig, error) {
	config := NewFlagsConfig()
	return config, config.Parse(in)
}

func (c *FlagsConfig) ParseFile(file string) error {
	f, err := os.Open(file)
	if err != nil {
		return err
	}
	defer f.Close()
	return c.Parse(f)
}

func (c *FlagsConfig) Parse(readerIn io.Reader) error {
	reader := stripper.NewCommentStripper(readerIn)

	decoder, err := control.NewDecoder(bufio.NewReader(reader), nil)
	if err != nil {
		return err
	}

	for {
		entry := FlagsConfigEntry{}

		err := decoder.Decode(&entry)
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}

		if len(entry.Commands) == 0 {
			entry.Commands = []string{""}
		}

		for _, command := range entry.Commands {
			targetEntry := (*c)[command]
			targetEntry.Apply(entry)
			(*c)[command] = targetEntry
		}
	}

	return nil
}
