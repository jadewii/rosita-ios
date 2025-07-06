#!/bin/bash

# Script to validate and troubleshoot RositaAUv3

echo "Checking for RositaAUv3 Audio Unit..."
echo ""

# Check if auval can find the plugin
echo "Searching for Rosita in registered Audio Units:"
auval -a | grep -i rosita

echo ""
echo "Running validation on RositaAUv3..."
# Validate the specific AU (using the manufacturer code and subtype from Info.plist)
auval -v aumu rsit JAde

echo ""
echo "Additional troubleshooting commands:"
echo "- To force re-scan of Audio Units: killall -9 AudioComponentRegistrar"
echo "- To check system logs: log show --predicate 'subsystem == \"com.apple.audio.AudioComponentRegistrar\"' --last 5m"
echo "- To manually register: pluginkit -a <path-to-appex> -v"