/**
 * Implements a fuzzy search algorithm, yielding the same results as what the
 * fuzzy match algorithm in VSCode matches. This is basically a fuzzy `contains`
 * / `canFind` method for strings and arrays.
 *
 * However this library does not offer any fuzzy match scoring. This
 * functionality might be added in the future in new methods. The check-only
 * methods are ideal if the result is intended to be passed into other systems
 * that are responsible for display and sorting. (e.g. from DCD / serve-d into
 * VSCode, IDEs or other editors)
 *
 * It is quite efficient, allocates no memory and works with character ranges as
 * well as simple arrays. Pre-compiled string versions are available for reduced
 * compilation time for simple string/wstring/dstring matches.
 *
 * This works by going through the search string character by character, on
 * every matching character, the matcher string advances by one character. If
 * the matcher string is completely checked, the fuzzy match returns true.
 *
 * Methods:
 * - $(LREF fuzzyMatchesUni) - fuzzy contains method with unicode decoding
 * - $(LREF fuzzyMatchesRaw) - fuzzy contains method on arbitrary arrays
 */
module fuzzymatch;

version (D_BetterC)
{
}
else
	version = HasUnicodeFuzzymatch;

// import std.traits : isSomeString;
private enum bool shouldBeDecoded(T) = is(immutable T == immutable C[], C) && (is(C == char) || is(C == wchar));

pragma(inline, true)
private bool empty(T)(scope const(T)[] s) @safe pure nothrow @nogc
{
	return s.length == 0;
}

version (HasUnicodeFuzzymatch)
{
	/**
	 * Checks if doesThis contains matchThis in a way that a fuzzy search would find
	 * it.
	 *
	 * Performs basic case-insensitivity checks. UTF decodes strings and wstrings,
	 * skipping invalid characters. Note that the case-insensitive version does not
	 * check for unicode sequences, such as German `ß` matching `ss`, but only by
	 * comparing single codepoints using their upper variant.
	 *
	 * To perform no UTF decoding, either call this method with dstrings (UTF32
	 * strings) or, if you checked that the string ONLY contains single code unit
	 * per user-conceived character, by using `.representation` and then
	 * $(LREF fuzzyMatchesRaw) - note that this method only works case-sensitive and
	 * won't perform any case-transformations!
	 *
	 * If you have strings, you can save compilation speed by using the pre-compiled
	 * method $(LREF fuzzyMatchesString), which accepts strings, wstring or dstrings.
	 *
	 * The $(LEF fuzzyMatchesStringCS) method is another pre-compiled version of
	 * this fuzzyMatchesUni function, but performs caseSensitive checks.
	 *
	 * See_Also:
	 * - $(LREF fuzzyMatchesRaw) - performs no unicode decoding, not usable with
	 *   strings, but with representations.
	 */
	bool fuzzyMatchesUni(bool caseSensitive = false, R1, R2)(scope R1 doesThis, scope R2 matchThis) @safe pure nothrow @nogc
		if (!(is(R1 == dstring) && is(R2 == dstring) && caseSensitive))
	{
		import std.utf : byUTF, decode, UseReplacementDchar;
		static if (!caseSensitive)
			import std.uni : toUpper;

		if (matchThis.empty)
			return true;

		size_t i = 0;
		dchar next = matchThis.decode!(UseReplacementDchar.yes)(i);
		const matchThisLength = matchThis.length;
		static if (!caseSensitive)
			next = next.toUpper;
		foreach (c; doesThis.byUTF!dchar)
		{
			static if (!caseSensitive)
				bool match = toUpper(c) == next;
			else
				bool match = c == next;
			if (match)
			{
				if (i >= matchThisLength)
					return true;
				next = matchThis.decode!(UseReplacementDchar.yes)(i);
				static if (!caseSensitive)
					next = next.toUpper;
			}
		}
		return false;
	}

	/// ditto
	pragma(inline, true)
	bool fuzzyMatchesUni(bool caseSensitive = false, R1, R2)(scope R1 doesThis, scope R2 matchThis) @safe pure nothrow @nogc
		if (is(R1 == dstring) && is(R2 == dstring) && caseSensitive)
	{
		// fast code for simple dstring, dstring + case sensitive code path.
		return fuzzyMatchesRaw(doesThis, matchThis);
	}

	/// ditto
	bool fuzzyMatchesString(scope const(char)[] doesThis, scope const(char)[] matchThis) @safe pure nothrow @nogc
	{
		return fuzzyMatchesUni(doesThis, matchThis);
	}

	/// ditto
	bool fuzzyMatchesString(scope const(wchar)[] doesThis, scope const(wchar)[] matchThis) @safe pure nothrow @nogc
	{
		return fuzzyMatchesUni(doesThis, matchThis);
	}

	/// ditto
	bool fuzzyMatchesString(scope const(dchar)[] doesThis, scope const(dchar)[] matchThis) @safe pure nothrow @nogc
	{
		return fuzzyMatchesUni(doesThis, matchThis);
	}

	/// ditto
	bool fuzzyMatchesStringCS(scope const(char)[] doesThis, scope const(char)[] matchThis) @safe pure nothrow @nogc
	{
		return fuzzyMatchesUni!true(doesThis, matchThis);
	}

	/// ditto
	bool fuzzyMatchesStringCS(scope const(wchar)[] doesThis, scope const(wchar)[] matchThis) @safe pure nothrow @nogc
	{
		return fuzzyMatchesUni!true(doesThis, matchThis);
	}

	/// ditto
	bool fuzzyMatchesStringCS(scope const(dchar)[] doesThis, scope const(dchar)[] matchThis) @safe pure nothrow @nogc
	{
		return fuzzyMatchesUni!true(doesThis, matchThis);
	}

	///
	@safe unittest
	{
		assert( "foo".fuzzyMatchesString(""));
		assert( "foo".fuzzyMatchesString("Fo"));
		assert(!"foo".fuzzyMatchesString("b"));

		assert( "foo".fuzzyMatchesStringCS(""));
		assert(!"foo".fuzzyMatchesStringCS("Fo"));
		assert( "foo".fuzzyMatchesStringCS("fo"));
		assert(!"foo".fuzzyMatchesStringCS("b"));

		assert( "path/to/game.txt".fuzzyMatchesString("path/to/game.txt"));
		assert( "path/to/game.txt".fuzzyMatchesString("path/to/game."));
		assert( "path/to/game.txt".fuzzyMatchesString("pathgametxt"));
		assert( "path/to/game.txt".fuzzyMatchesString("ptg"));
		assert(!"path/to/game.txt".fuzzyMatchesString("ptf"));
		assert("path/to/game.txt".fuzzyMatchesString("game.txt"));
		assert(!"path/to/game.txt".fuzzyMatchesString("work.txt"));
	}

	///
	@safe unittest
	{
		import std.path : chainPath;
		assert( chainPath("path", "to", "game.txt").fuzzyMatchesUni("ptg"w));
		assert(!chainPath("path", "to", "game.txt").fuzzyMatchesUni("root"w));
	}

	@safe unittest
	{
		assert("foo".fuzzyMatchesString(""));
		assert("foo"w.fuzzyMatchesString(""w));
		assert("foo"d.fuzzyMatchesString(""d));
		assert("foo".fuzzyMatchesString("Fo"));
		assert("foo"w.fuzzyMatchesString("Fo"w));
		assert("foo"d.fuzzyMatchesString("Fo"d));
		assert(!"foo".fuzzyMatchesString("b"));
		assert(!"foo"w.fuzzyMatchesString("b"w));
		assert(!"foo"d.fuzzyMatchesString("b"d));

		assert("path/to/game.txt".fuzzyMatchesString("pathgametxt"));
		assert("path/to/game.txt".fuzzyMatchesString("ptg"));
		assert(!"path/to/game.txt".fuzzyMatchesString("ptf"));
		assert("path/to/game.txt"w.fuzzyMatchesString("pathgametxt"));
		assert("path/to/game.txt"w.fuzzyMatchesString("ptg"));
		assert(!"path/to/game.txt"w.fuzzyMatchesString("ptf"));
		assert("path/to/game.txt".fuzzyMatchesString("pathgametxt"w));
		assert("path/to/game.txt".fuzzyMatchesString("ptg"w));
		assert(!"path/to/game.txt".fuzzyMatchesString("ptf"w));

		assert("path/to/game.txt".fuzzyMatchesStringCS("pathgametxt"));
		assert("path/to/game.txt".fuzzyMatchesStringCS("ptg"));
		assert(!"path/to/game.txt".fuzzyMatchesStringCS("ptf"));
		assert("path/to/game.txt"w.fuzzyMatchesStringCS("pathgametxt"));
		assert("path/to/game.txt"w.fuzzyMatchesStringCS("ptg"));
		assert(!"path/to/game.txt"w.fuzzyMatchesStringCS("ptf"));
		assert("path/to/game.txt".fuzzyMatchesStringCS("pathgametxt"w));
		assert("path/to/game.txt".fuzzyMatchesStringCS("ptg"w));
		assert(!"path/to/game.txt".fuzzyMatchesStringCS("ptf"w));
	}
}

/**
 * Works like $(LREF fuzzyMatchesUni), but does not do any UTF decoding, but
 * rather just goes through the arrays element-by-element.
 *
 * This method works case-sensitive if dstrings are passed into it.
 *
 * This method has no dependency on the standard library and should work with
 * betterC.
 */
bool fuzzyMatchesRaw(R1, R2)(scope const R1 doesThis, scope const R2 matchThis) @safe pure nothrow @nogc
	if (!shouldBeDecoded!R1 && !shouldBeDecoded!R2)
{
	if (matchThis.empty)
		return true;

	size_t i;
	dchar next = matchThis[i++];
	const matchThisLength = matchThis.length;
	foreach (c; doesThis)
	{
		if (c == next)
		{
			if (i >= matchThisLength)
				return true;
			next = matchThis[i++];
		}
	}
	return false;
}

///
@safe unittest
{
	assert( "foo"d.fuzzyMatchesRaw(""d));
	assert( "foo"d.fuzzyMatchesRaw("fo"d));
	assert(!"foo"d.fuzzyMatchesRaw("Fo"d));
	assert(!"foo"d.fuzzyMatchesRaw("b"d));

	assert( "path/to/game.txt"d.fuzzyMatchesRaw("pathgametxt"d));
	assert( "path/to/game.txt"d.fuzzyMatchesRaw("ptg"d));
	assert(!"path/to/game.txt"d.fuzzyMatchesRaw("ptf"d));

	assert([1, 2, 3, 4, 5].fuzzyMatchesRaw([1, 3, 5]));
	assert(![1, 2, 3, 4, 5].fuzzyMatchesRaw([1, 5, 3]));
	assert([1, 2, 3, 4, 5].fuzzyMatchesRaw([1, 5]));
	assert([1, 2, 3, 4, 5].fuzzyMatchesRaw([5]));
	assert(![1, 2, 3, 4, 5].fuzzyMatchesRaw([0]));
}

