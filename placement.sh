#!/bin/bash

# Parameter
CSV_FILE="./avs-sql.csv" # Pfad zur CSV-Datei

# Azure-Authentifizierung
echo "Authenticating to Azure..."
az login --tenant "YOURTENANT" --subscription "YOURSUB" --use-device-code
if [ $? -ne 0 ]; then
  echo "Azure authentication failed."
  exit 1
fi
echo "Authentication successful."

# Prüfen, ob die CSV-Datei existiert
if [ ! -f "$CSV_FILE" ]; then
  echo "CSV file not found at $CSV_FILE"
  exit 1
fi

# Lesen der CSV-Datei und Verarbeitung jeder Zeile
while IFS=',' read -r PolicyName Type ClusterName HostNames VMNames Enabled ResourceGroupName PrivateCloudName SubscriptionId
do
  echo "Processing policy: $PolicyName"

  # Werte aus CSV extrahieren und verarbeiten
  State="Disabled"
  if [ "$Enabled" == "Enabled" ]; then
    State="Enabled"
  fi

  # Host- und VM-Mitglieder vorbereiten
  IFS=',' read -ra HOST_ARRAY <<< "$HostNames"
  IFS=',' read -ra VM_ARRAY <<< "$VMNames"

  # Host-Mitglieder als kommaseparierte Liste
  HOST_MEMBERS=$(IFS=','; echo "${HOST_ARRAY[*]}")
  # VM-Mitglieder als kommaseparierte Liste
  VM_MEMBERS=$(IFS=','; echo "${VM_ARRAY[*]}")

  # CLI-Befehl ausführen
  echo "Creating/Updating Placement Policy: $PolicyName"
  az vmware placement-policy vm-host create \
    --affinity-type "$Type" \
    --cluster-name "$ClusterName" \
    --host-members "$HOST_MEMBERS" \
    --name "$PolicyName" \
    --private-cloud "$PrivateCloudName" \
    --resource-group "$ResourceGroupName" \
    --vm-members "$VM_MEMBERS" \
    --state "$State"

  if [ $? -ne 0 ]; then
    echo "Failed to create/update Placement Policy: $PolicyName"
    continue
  fi
  echo "Placement Policy $PolicyName created/updated successfully."

done < <(tail -n +2 "$CSV_FILE") # Kopfzeile überspringen

echo "Placement policy creation/update process completed."
