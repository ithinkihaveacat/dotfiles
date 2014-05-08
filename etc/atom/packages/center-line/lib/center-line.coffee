
module.exports =
  activate: (state) ->
    atom.workspaceView.command "center-line:toggle", => @toggle()

  toggle: ->
    view = atom.workspaceView.getActiveView()
    editor = view?.getEditor()
    if not editor?
      return

    # Get the cursor position and screen boundaries

    cursor = editor.getCursorScreenPosition()

    rows =
      first: view.getFirstVisibleScreenRow()
      last: view.getLastVisibleScreenRow()
      cursor: cursor.row
      final: editor.getLastScreenRow()

    rows.center = rows.first + Math.round((rows.last - rows.first) / 2) - 1

    if rows.first is 0 and rows.last is rows.final
      return

    # Figure out where we are and where we want to go.

    here = @whereAreWe(rows)

    cycles =
      center: 'first'
      first:  'last'
      last:   'center'
      other:  'center'
    goto = cycles[here]

    # Now go.  We'll scroll ourselves since EditorView.scrollVertically seems to have a bug and
    # does not scroll if the requested pixel is already on the screen.

    pixel = view.pixelPositionForScreenPosition(cursor).top

    if goto is 'center'
      pixel -= (view.scrollView.height() / 2);
    else if goto is 'last'
      # Back up two lines since the scrollbar height doesn't seem to be accounted
      # for in scrollView.height.  Make sure slack is at last one
      pixel -= view.scrollView.height() - view.lineHeight * 2

    view.scrollTop(pixel)

  whereAreWe: (rows) ->
    # Normally we just compare the cursor to the 3 interesting rows.  However if we are near
    # the top or bottom of the document we won't be able to scroll the cursor all the way to
    # the top or bottom of the window.  Check for those cases first.

    if rows.last is rows.final
      'first'
    else if rows.first is 0
      'last'
    else
      slack = 1
      for key in ['first', 'center', 'last']
        row = rows[key]
        if (row - slack) <= rows.cursor <= (row + slack)
          return key
      'other'
