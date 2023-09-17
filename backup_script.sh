#!/bin/bash

echo -n "Enter GitHub token: "
read -s token
echo
username=$(curl -s -H "Authorization: token $token" https://api.github.com/user | jq -r .login)
page=1

while : ; do
  repo_info=$(curl -s -H "Authorization: token $token" "https://api.github.com/user/repos?page=$page&per_page=200")
  
  if [ "$(echo "$repo_info" | jq -r '. | length')" == "0" ]; then
    break
  fi
  
  for repo in $(echo "$repo_info" | jq -r '.[] | @base64'); do
    repo_name=$(echo "$repo" | base64 --decode | jq -r .name)
    repo_url=$(echo "$repo" | base64 --decode | jq -r .clone_url)
    repo_url=$(echo "$repo_url" | sed -e "s#https://#https://${username}:${token}@#")
    
    # Si le dossier du dépôt existe déjà, le supprimer
    if [ -d "$repo_name" ]; then
        echo "Suppression du dossier $repo_name existant..."
        rm -rf "$repo_name"
    fi
    
    # Clonage du dépôt
    echo "Clonage du dépôt $repo_name..."
    git clone "$repo_url"
  done

  ((page++))
done
