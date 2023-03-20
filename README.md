# fuzzymatch

Dead-simple, efficient string and array fuzzy matching library.

Usable for everyone:
- GC & phobos range users
- betterC users (case-sensitive dstring or no-decode array check only)
- `@nogc` users (in all cases)
- `string`, `wstring`, `dstring` users

```d
import fuzzymatch;

assert("path/to/game.txt".fuzzyMatchesString("path/to/game.txt"));
assert("path/to/game.txt".fuzzyMatchesString("path/to/game."));
assert("path/to/game.txt".fuzzyMatchesString("pathgametxt"));
assert("path/to/game.txt".fuzzyMatchesString("ptg"));
assert("path/to/game.txt".fuzzyMatchesString("game.txt"));
assert(!"path/to/game.txt".fuzzyMatchesString("work.txt"));
```
## Documentation

Implements a fuzzy search algorithm, yielding the same results as what the
fuzzy match algorithm in VSCode matches. This is basically a fuzzy `contains`
/ `canFind` method for strings and arrays.

However this library does not offer any fuzzy match scoring. This
functionality might be added in the future in new methods. The check-only
methods are ideal if the result is intended to be passed into other systems
that are responsible for display and sorting. (e.g. from DCD / serve-d into
VSCode, IDEs or other editors)

It is quite efficient, allocates no memory and works with character ranges as
well as simple arrays. Pre-compiled string versions are available for reduced
compilation time for simple string/wstring/dstring matches.

This works by going through the search string character by character, on
every matching character, the matcher string advances by one character. If
the matcher string is completely checked, the fuzzy match returns true.

Methods:
- `fuzzyMatchesUni` - fuzzy contains method with unicode decoding
- `fuzzyMatchesRaw` - fuzzy contains method on arbitrary arrays


### fuzzyMatchesUni

```d
// rough definitions:
bool fuzzyMatchesUni(
	bool caseSensitive = false, R1, R2
)(
	in /* any char range or string */ R1 doesThis,
	in /* any char range or string */ R2 matchThis
) @safe pure nothrow @nogc

// pre-compiled case-insensitive variant:
bool fuzzyMatchesString(
	in string /* or wstring or dstring */ doesThis,
	in string /* or wstring or dstring */ matchThis
) @safe pure nothrow @nogc

// case-sensitive variant:
bool fuzzyMatchesStringCS(...) @safe pure nothrow @nogc
```

Checks if doesThis contains matchThis in a way that a fuzzy search would find
it.

Performs basic case-insensitivity checks. UTF decodes strings and wstrings,
skipping invalid characters. Note that the case-insensitive version does not
check for unicode sequences, such as German `ß` matching `ss`, but only by
comparing single codepoints using their upper variant.

To perform no UTF decoding, either call this method with dstrings (UTF32
strings) or, if you checked that the string ONLY contains single code unit
per user-conceived character, by using `.representation` and then
`fuzzyMatchesRaw` - note that this method only works case-sensitive and
won't perform any case-transformations!

If you have strings, you can save compilation speed by using the pre-compiled
method `fuzzyMatchesString`, which accepts strings, wstring or dstrings.

The `fuzzyMatchesStringCS` method is another pre-compiled version of
this fuzzyMatchesUni function, but performs caseSensitive checks.

See_Also:
- `fuzzyMatchesRaw` - performs no unicode decoding, not usable with
strings, but with representations.


### fuzzyMatchesRaw

```d
// rough definitions:
bool fuzzyMatchesRaw(R1, R2)(
	in /* any range or array */ R1 doesThis,
	in /* any range or array */ R2 matchThis
) @safe pure nothrow @nogc
```

Works like `fuzzyMatchesUni`, but does not do any UTF decoding, but
rather just goes through the arrays element-by-element.

This method works case-sensitive if dstrings are passed into it.

This method has no dependency on the standard library and should work with
betterC.

