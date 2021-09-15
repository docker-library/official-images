if git diff-index --quiet HEAD --; then
    echo " No changes"
else
    echo " Changes"
fi
