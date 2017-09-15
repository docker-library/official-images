package execpipe_test

import (
	"os"
	"os/exec"
	"testing"

	"github.com/docker-library/go-dockerlibrary/pkg/execpipe"
)

func TestStdoutPipeError(t *testing.T) {
	cmd := exec.Command("nothing", "really", "matters", "in", "the", "end")

	// set "Stdout" so that "cmd.StdoutPipe" fails
	// https://golang.org/src/os/exec/exec.go?s=16834:16883#L587
	cmd.Stdout = os.Stdout

	_, err := execpipe.Run(cmd)
	if err == nil {
		t.Errorf("Expected execpipe.Run to fail -- it did not")
	}
}

func TestStartError(t *testing.T) {
	// craft a definitely-invalid command so that "cmd.Start" fails
	// https://golang.org/src/os/exec/exec.go?s=8739:8766#L303
	_, err := execpipe.RunCommand("nothing-really-matters-in-the-end--bogus-command")
	if err == nil {
		t.Errorf("Expected execpipe.RunCommand to fail -- it did not")
	}
}
