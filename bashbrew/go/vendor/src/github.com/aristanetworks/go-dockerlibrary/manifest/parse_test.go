package manifest_test

import (
	"strings"
	"testing"

	"github.com/docker-library/go-dockerlibrary/manifest"
)

func TestParseError(t *testing.T) {
	invalidManifest := `this is just completely bogus and invalid no matter how you slice it`

	man, err := manifest.Parse(strings.NewReader(invalidManifest))
	if err == nil {
		t.Errorf("Expected error, got valid manifest instead:\n%s", man)
	}
	if !strings.HasPrefix(err.Error(), "cannot parse manifest in either format:") {
		t.Errorf("Unexpected error: %v", err)
	}
}
