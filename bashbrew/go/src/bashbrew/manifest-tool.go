package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
)

func manifestToolPushFromSpec(yamlSpec string) error {
	yamlFile, err := ioutil.TempFile("", "bashbrew-manifest-tool-yaml-")
	if err != nil {
		return err
	}
	defer os.Remove(yamlFile.Name())

	if _, err := yamlFile.Write([]byte(yamlSpec)); err != nil {
		return err
	}
	if err := yamlFile.Close(); err != nil {
		return err
	}

	args := []string{"push", "from-spec", "--ignore-missing", yamlFile.Name()}
	if debugFlag {
		args = append([]string{"--debug"}, args...)
		fmt.Printf("$ manifest-tool %q\n", args)
	}
	cmd := exec.Command("manifest-tool", args...)
	cmd.Stderr = os.Stderr
	if debugFlag {
		cmd.Stdout = os.Stdout
	}

	return cmd.Run()
}
