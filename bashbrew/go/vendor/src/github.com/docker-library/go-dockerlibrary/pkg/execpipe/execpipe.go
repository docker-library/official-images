package execpipe

import (
	"io"
	"os/exec"
)

// "io.ReadCloser" interface to a command's output where "Close()" is effectively "Wait()"
type Pipe struct {
	cmd *exec.Cmd
	out io.ReadCloser
}

// convenience wrapper for "Run"
func RunCommand(cmd string, args ...string) (*Pipe, error) {
	return Run(exec.Command(cmd, args...))
}

// start "cmd", capturing stdout in a pipe (be sure to call "Close" when finished reading to reap the process)
func Run(cmd *exec.Cmd) (*Pipe, error) {
	pipe := &Pipe{
		cmd: cmd,
	}
	if out, err := pipe.cmd.StdoutPipe(); err != nil {
		return nil, err
	} else {
		pipe.out = out
	}
	if err := pipe.cmd.Start(); err != nil {
		pipe.out.Close()
		return nil, err
	}
	return pipe, nil
}

func (pipe *Pipe) Read(p []byte) (n int, err error) {
	return pipe.out.Read(p)
}

func (pipe *Pipe) Close() error {
	return pipe.cmd.Wait()
}
