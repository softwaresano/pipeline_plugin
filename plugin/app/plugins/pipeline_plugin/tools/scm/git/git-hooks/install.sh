#!/bin/bash
rm -Rf ~/.git_template
cp -r $(dirname $0)/.git_template ~/
git config --global init.templatedir "~/.git_template"
echo "git templates installed successfully"
