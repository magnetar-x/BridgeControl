#!/bin/bash
stat=$( omarchy plugin list | grep "BridgeControl" | awk '{print $2}' )
if [[ $stat == 'enabled' ]]; then
  omarchy plugin disable BridgeControl
else 
  omarchy plugin enable BridgeControl
  sleep 0.5
  omarchy restart shell
  omarchy-shell shell summon BridgeControl '{}'
fi
