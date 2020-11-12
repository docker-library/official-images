// # goToLine.js
//
// Contains methods for showing a form allowing instant jumping
// to any line in a file. Currently only works if line numbers
// have been enabled in the output

// Wrap everything inside a closure so we don't get any collisions in
// the global scope
(function() {
  // Some useful variables
  var jumpBoxShown = false;
  var jumpTimeout;

  /**
   * ## jumpFormKeyDown
   *
   * Fired when a key is pressed on the jump form. Performs the
   * appropriate action depending on which key was pressed
   *
   * @param {KeyDownEvent} e The key event
   */
  function jumpFormKeyDown(e) {
    e = e || window.event;

    // 27 = esc, so hide the form
    if (e.keyCode == 27) {
      document.body.removeChild(document.getElementById('jumpto'));
      jumpBoxShown = false;

    // Otherwise, most likely the user has typed or deleted on the
    // form, so queue a jump. Don't do it immediately do avoid
    // disorientating jumps during quick typing
    } else {
      clearTimeout(jumpTimeout);
      jumpTimeout = setTimeout(doJump, 150);
    }
  }

  /**
   * ## addEvent
   *
   * Helper function for binding DOM events
   *
   * @param {Element} obj The DOM element to bind to
   * @param {string} evt The name of the event to bind to
   * @param {function} func Listener to attach to the event
   */
  function addEvent(obj, evt, func, a) {
    if ((a = obj.addEventListener)) {
      a.call(obj, evt, func, false);
    } else {
      obj.attachEvent('on' + evt, func);
    }
  }

  /**
   * ## jumpFormSubmitted
   *
   * Called when the user hits enter on the jump form
   * so find the given line and jump to it
   *
   * @param {FormSubmitEvent} e The submit event
   */
  function jumpFormSubmitted(e) {
    e = e || window.event;
    e.preventDefault();

    doJump();

    // Hide the jump box
    document.body.removeChild(document.getElementById('jumpto'));
    jumpBoxShown = false;

    return false;
  }

  /**
   * ## doJump
   *
   * Performs the line jump by manipulating the location hash
   */
  function doJump() {
    if (!jumpBoxShown) return;

    // Figure out which line we need to jump to
    var line = document.getElementById('jumpbox').value;

    // Grab the line anchor if it exists
    var theLine = document.getElementById('line-' + line);

    // If it doesn't exist, there's not much we can do
    if (!theLine) return;

    // If it does exist, jump to it
    window.location.hash = 'line-' + line;
  }

  /**
   * ## showJumpBox
   *
   * Constructs and shows the jump box
   */
  function showJumpBox() {
    // If the box is already visible, do nothing
    if (jumpBoxShown) return;
    jumpBoxShown = true;

    // Create the containing element
    var f = document.createElement('div');
    f.id = 'jumpto';

    // Construct some basic HTML
    f.innerHTML = [
      '<div class="overlay"></div>',
      '<div class="box">',
      '<form id="jumpform">',
      '<input id="jumpbox" type="text" name="line" placeholder="Go to line..." autocomplete="off" />',
      '</form>',
      '</div>'
    ].join('');

    // Add the keydown event
    addEvent(f, 'keydown', jumpFormKeyDown);

    // Add the container straight onto the body
    document.body.appendChild(f);

    // Focus the field, and bund the submit event
    document.getElementById('jumpbox').focus();
    addEvent(document.getElementById('jumpform'), 'submit', jumpFormSubmitted);
  }

  /**
   * ## goToLine_kd
   *
   * Fired as a global keyDown event on the document. Checks
   * if ctrl/cmd+G has been pressed and shows the jump form
   *
   * @param {KeyDownEvent} e The key event
   */
  function goToLine_kd(e) {
    e = e || window.event;

    // 71 = g, so listen for ctrl/cmd+P
    if (e.keyCode === 71 && (e.ctrlKey || e.metaKey)) {
      showJumpBox();
      e.preventDefault();
      return false;
    }
  }

  // Attach the global event to the document
  addEvent(document, 'keydown', goToLine_kd);
})();
