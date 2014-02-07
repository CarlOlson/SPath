SPath
=====

XPath like query system for s-expressions in Scheme or Racket


Syntax
------
    (spath s-exp query)
    ex, (spath sexp "//tag//[@/id=3]")

<table>
  <tr>
    <td>///tag</td>
    <td>Searches all levels for 'tag</td>
  </tr>
  <tr>
    <td>//tag</td>
    <td>Searches until it reaches 'tag</td>
  </tr>
  <tr>
    <td>/tag</td>
    <td>Searches the top level for 'tag</td>
  </tr>
  <tr>
    <td>[/tag]</td>
    <td>Keeps groups with a 'tag sub-group</td>
  </tr>
  <tr>
    <td>[/tag=1]</td>
    <td>Keeps groups with a 'tag sub-group and value of 1</td>
  </tr>
  <tr>
    <td>[/tag='string']</td>
    <td>As above, but a value of "string"</td>
  </tr>
  <tr>
    <td>[/tag=a]</td>
    <td>As above, but a value of 'a</td>
  </tr>
</table>

<i>Filtering brackets [ ] use multiple foreward slashes / to the same effect</i>
