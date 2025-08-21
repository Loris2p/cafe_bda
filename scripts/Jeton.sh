#!/bin/bash

# Variables
TENANT_ID="b8c19512-2aed-471d-a8d1-9b06e7da786a"
CLIENT_ID="ccbc3e70-38ba-48c7-adac-8cb4afba869b"
CLIENT_SECRET="MTt8Q~Joe-H8B0~cTh9bQWoO0Oivnph2f8rhvaM4"
TOKEN_URL="https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token"

# Requête pour obtenir le jeton d'accès
response=$(curl -X POST "$TOKEN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID" \
  -d "scope=https://graph.microsoft.com/.default" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "grant_type=client_credentials")

# Extraire le jeton d'accès de la réponse
access_token=$(echo "$response" | jq -r '.access_token')

# Afficher le jeton d'accès
echo "Access Token: $access_token"
