#!/bin/bash

# TODO: Move some of the common/looped code into functions (DRY)

shopt -s nullglob

# Get default release
. ./repo-settings.sh

# Text in this file will appear at the start of the top-level index
INTRO=intro.md

# Filename for index in each dir
INDEX=index.md

for b_or_t in branches tags; do
    echo "Processing $b_or_t $INDEX..."
    cd "$b_or_t"
    for dir in */; do
        dirname="${dir%%/}"
        echo "Making $dirname/$INDEX"
        cd "$dir"
            echo -e "# Documentation for $dirname\n" >> "$INDEX"
            if [ -d docs ]; then
                for doc in docs/[1-9]*.md; do
                    no_ext="${doc%%.md}"
                    # Spaces causing problems so rename extracted docs to use underscore
                    underscore_space_doc="${doc// /_}"
                    mv "$doc" "$underscore_space_doc"

                    # Top level documents have numbers ending in '.0' or '.0.'
                    match_top_level='^docs/[1-9][0-9]*\.0\.? '
                    if [[ "$doc" =~ $match_top_level ]]; then
                        linktext="${no_ext#* }"
                        echo "- [$linktext]($underscore_space_doc)" >> "$INDEX"
                    else
                        # Removing the top-level part of lower-level link texts
                        # that is the part up to the hyphen and following space
                        linktext="${no_ext#* - }"
                        echo "  - [$linktext]($underscore_space_doc)" >> "$INDEX"
                    fi
                done
            fi

            if [ -d html-APIs ]; then
                INDEX_APIS="html-APIs/$INDEX"
                echo -e "\n## APIs for $dirname\n" >> "$INDEX"
                echo -e "# APIs for $dirname\n" > "$INDEX_APIS"
                for api in html-APIs/*.html; do
                    no_ext="${api%%.html}"
                    linktext="${no_ext##*/}"
                    echo "- [$linktext](${api##*/})" >> "$INDEX_APIS"
                    echo "- [$linktext]($api)" >> "$INDEX"
                done
            fi

            if [ -d html-APIs/schemas ]; then
                INDEX_SCHEMAS="html-APIs/schemas/$INDEX"
                echo -e "\n### [JSON Schemas](html-APIs/schemas/)\n" >> "$INDEX"
                echo -e "## JSON Schemas\n" > "$INDEX_SCHEMAS"
                for schema in html-APIs/schemas/*.json; do
                    no_ext="${schema%%.json}"
                    linktext="${no_ext##*/}"
                    echo "- [$linktext](${schema##*/})" >> "$INDEX_SCHEMAS"
                done
            fi

            if [ -d examples ]; then
                INDEX_EXAMPLES="examples/$INDEX"
                echo -e "\n### [Examples](examples/)\n" >> "$INDEX"
                echo -e "## Examples\n" > "$INDEX_EXAMPLES"
                for example in examples/*.json; do
                    no_ext="${example%%.json}"
                    linktext="${no_ext##*/}"
                    echo "- [$linktext](${example##*/})" >> "$INDEX_EXAMPLES"
                done
            fi

            cd ..
    done
    cd ..
done

echo "Making top level $INDEX"

cat "$INTRO" > "$INDEX"
echo >> "$INDEX"

# Add the default links at the top - correct the links while copying text
if [ "$DEFAULT_RELEASE" ]; then
    echo "Adding in contents of $INDEX for default release $DEFAULT_RELEASE"
    sed "s:(:(tags/$DEFAULT_RELEASE/:" "tags/$DEFAULT_RELEASE/$INDEX" >> "$INDEX"
elif [ "$DEFAULT_BRANCH" ]; then
    echo "Adding in contents of $INDEX for default branch $DEFAULT_BRANCH"
    sed "s:(:(branches/$DEFAULT_BRANCH/:" "branches/$DEFAULT_BRANCH/$INDEX" >> "$INDEX" 
fi

# TODO: DRY on the following...

echo Adding branches index...
INDEX_BRANCHES="branches/index.md"
echo "# Branches" > "$INDEX_BRANCHES"
echo -e "\n## Branches" >> "$INDEX"
for dir in branches/*; do
    [ ! -d $dir ] && continue
    branch="${dir##*/}"
    echo -e "\n[$branch](branches/$branch/)" >>  "$INDEX"
    echo -e "\n[$branch]($branch/)" >>  "$INDEX_BRANCHES"
done

echo Adding tags index...
INDEX_TAGS="tags/index.md"
echo "# Tags (Releases)" > "$INDEX_TAGS"
echo -e "\n## Tags (Releases)" >> "$INDEX"
for dir in tags/*; do
    [ ! -d $dir ] && continue
    tag="${dir##*/}"
    echo -e "\n[$tag](tags/$tag/)" >>  "$INDEX"
    echo -e "\n[$tag]($tag/)" >>  "$INDEX_TAGS"
done

echo Adding warnings to each autogenerated file...
find . -name "$INDEX" -exec perl -pi -e 'print "<!-- AUTOGENERATED FILE: DO NOT EDIT -->\n\n" if $. == 1' {} \;