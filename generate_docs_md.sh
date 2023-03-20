#!/bin/bash
dmd -o- -w -Xfdocs.json -Df__dummy.html source/fuzzymatch.d
rm __dummy.html
echo "## Documentation" > fuzzymatch.md
echo >> fuzzymatch.md
jq -r ".[0].comment" docs.json >> fuzzymatch.md
echo >> fuzzymatch.md
echo "### fuzzyMatchesUni" >> fuzzymatch.md
echo >> fuzzymatch.md
jq -r ".[0].members[] | select(.name == \"fuzzyMatchesUni\") | .comment" docs.json >> fuzzymatch.md
echo >> fuzzymatch.md
echo "### fuzzyMatchesRaw" >> fuzzymatch.md
echo >> fuzzymatch.md
jq -r ".[0].members[] | select(.name == \"fuzzyMatchesRaw\") | .comment" docs.json >> fuzzymatch.md
echo >> fuzzymatch.md
