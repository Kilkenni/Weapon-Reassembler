# Weapon-Reassembler
A mod for tinkering with boomsticks in Starbound. Does not change the stats. Or does it?..

Known limitations:

- Can not combine certain altModes with physical damage (namely, Energy Lance and Explosive Burst).

It can't be avoided since these altModes are locked to appropriate elements, and changing them will create too much incompatibilities. To avoid any problems this combination should be locked by default with my internal checks.

- Common-rarity guns can't change primary fire element, normal fire always stays "physical".

A limitation on Starbound's side where common-rarity weapons are STRICTLY "physical" and weapons of higher rarity are STRICTLY elemental.

altMode element changes, however, are ok (i.e. you can integrate Energy Lance into common gun if you change element from physical to any other but its primary fire will still be physical).

- Uncommon guns and better can't change primary fire to "physical".

All of my attempts break the original weapon. Supposedly it is a limitation on SB's side as well. Since fire sound modification is already supported (and type of ammo WILL be supported at some point) I don't see it as a big issue.

You can still integrate common-level altModes into uncommon weapons.

- Removing dyes with dye remover does not remove the "Custom" label in the tooltip.

Intended. While I've made using dye remover return original vanilla colors, it doesn't guarantee all OTHER parameters are vanilla. If you want a guaranteed complete return to vanilla state use "Revert" instead.


## THANKS
C0bra5 - for his useful Recolor Tool (http://community.playstarbound.com/threads/update-v1-1-2-recolor-maker-2.105981/)

It would take me ages to create palettes without it.

C0rdyc3p5 - for his friendly SMK, the StarModder's Kit (http://community.playstarbound.com/threads/starmodder-kit-the-modding-ide-wip.117686/)

I usually use it for packing/unpacking my .pak files.

## TODO:

- [DONE] Option to copy single weapon part visuals
- [DONE] Compatible common/uncommon/rare weapons
- [DONE] Optional sound replication
- [DONE] Changing weapon's alt mode
- [BONUS] Now with 100% more feedback on errors
- [PARTIALLY DONE] Weapon reassemble preview
- [DONE] Changing weapon element
- [TOO MUCH HASSLE] Element: try to implement common gun elements and uncommon gun "physical" element
- [DONE] Element: implement UI locks for unavailable combinations
- [DONE] Move "Rename" to reassemble, recheck and fix this function
- [BONUS] Zooming weapon preview
- Informative UI
- [DONE] Recoloring weapon from scratch (dye punk, can you use it?)
- [DONE] Palettes for every dye, more palettes, palettes!
- [DONE] Do nothing with the weapon if no options are selected
- Applying reassembly resource costs
- Support for melee weapons
- Changing weapon projectile type (for grenade launchers etc) (will cost resources)
- Weapon altMode descriptions (inside the station? Icons? Book?)
- [DECLINED] Maybe: scanning a weapon to "remember" appearance (with no need for a template later)
- Upgrading weapon stats (will cost resources, will be limited - you won't be able to use a low-tier gun through the entire game)
- lulz
