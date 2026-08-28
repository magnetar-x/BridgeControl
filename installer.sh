#!/bin/bash
cd ..
mv BridgeControl ~/.config/omarchy/plugins/
cd ..
cd BridgeControl
cd ~/.config/omarchy/plugins/my.scifi.hud
find ~/.config/omarchy/plugins/BridgeControl -name *.qmlc -type f -delete
rm -rf ~/.cache/omarchy/
omarchy restart shell
omarchy-shell shell summon BridgeControl '{}'
echo "Dashboard added to screen!"
chmod +x toggler.sh
chmod +x add.sh
./add.sh
./toggler.sh
