# Multi_Clipboard for AHKv2

![Image:Example of Multi_Clipboard GUI](https://i.imgur.com/fw1q83V.png)

## Navigation
***
* [What does Multi_Clipboard do?](#what-does-multi_clipboard-do)
* [Properties](#properties)
 * [Number Set Properties](#number-set-properties)
 * [Modifier Actions Properties](#modifier-actions-properties)
 * ['Show All Clipboards' Hotkey](#show-all-clipboards-hotkey)
 * [Optional Properties](#optional-properties)
* [Methods](#methods)
* [Why remake it?](#why-remake-it)
* [Changelog](#changelog)

## What does Multi_Clipboard do?
A script with configurable multi-clipboard support.  
It turns any/some/all of the number sets on the keyboard into extra clipboard slots.  
You have 32 extra clipboard slots if all number sets are used.  
![Image:Keyboard Number Sets](https://i.imgur.com/mJlvE3T.png)  

The keys are controlled by modifier keys that you set.  
![Image:Modifier keys](https://i.imgur.com/r20VK4M.png)  

Defaults:  
`copy_mod` = `^` ctrl  
`show_mod` = `#` win  
`paste_mod` = `!` alt  

Example:  
Ctrl+numpad5 copies to slot numpad5  
Alt+numpad5 pastes whatever is stored in numpad5  
Win+numpad5 shows the contents of numpad5 in a popup GUI  

If a clipboard slot is empty, it shows as `<EMPTY>`.  
![Image:Gui with empty contents](https://i.imgur.com/Ez1j8DE.png)  

If a clipboard slot has text in it, it'll show the string.  
![Image:Gui with string contents](https://i.imgur.com/IehNVa4.png)  

Otherwise the clipboard slots has some binary data and shows `<BINARY DATA>`.  
The size and pointer of the data is included.  
![Image:Gui with binary contents](https://i.imgur.com/sNxEuRN.png)  

You can also view all clipboard key's contents [like in the main README example](https://i.imgur.com/fw1q83V.png).  
Or [individual ones](https://i.imgur.com/HoajrZO.png).  

## Properties

### [Number Set](https://i.imgur.com/mJlvE3T.png) Properties  
* `use_pad := 1` [bool]  
 Enables number pad keys (blue) to be used as clipboards.

* `use_bar := 1` [bool]  
 Enables the number bar row (red) to be used as clipboards.

* `use_f := 1` [bool]  
 Enables the Function keys (green) to be used as clipboards.

***
### Modifier Actions Properties
Modifier actions should be assigned a hotkey modifier symbol.  
Modifier keys are expected to be the same as AHK's [`Hotkey Modifier Symbols`](https://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols)  
Multiple symbols can be used.  
Symbols Indluce: `!` Alt, `^` Control, `#` Win, `+` Shift, `<` Left Side Modifier `>` Right Side Modifier  
The left and right side modifiers work. Setting copy to `<!` left alt and paste to `>!` right alt works without conflict.

* `copy_mod := '^'` [string]  
Modifier that copies to a clipboard key  

* `paste_mod := '!'` [string]  
Modifier that pastes from a clipboard key  

* `show_mod := '#'` [string]  
Modifier that shows contents of a clipboard key.

***
### 'Show All Clipboards' Hotkey  
* `all_hotkey := '^NumpadEnter'` [string]  
Shows the contents of all enabled clipboards. (Will not show clipboard contents that exceed 64000 total chars)  
This is the only full hotkey you define and can be any modifer+hotkey combo.  
 
***
### Optional Properties  

* `enable` [bool]  
true -> Enables all hotkeys (does not override disable_list property)  
false -> Disables all hotkeys  

* `send_hotkey` [bool]  
true  -> Native keystroke is included with the action remap  
false -> Native keystroke is replaced by the action remap  

* `quick_view` [bool]  
true  -> key down shows pop GUI and closes on key release  
false -> Key press pops up GUI and it stays up until closed  

* `hide_empty` [bool]  
true  -> Empty clipboards are omitted from display when shown  
false -> Empty clipboards show with key headers and as <EMPTY>  

* `hide_binary` [bool]  
true  -> Binary data clipboards are omitted from display when shown  
false -> Binary data clipboards show with key headers and as <BINARY_DATA>  

* `show_max_char` [num]  
Max number of characters to show from each clipboard string  
0 disables max and uses the full string  

* `disable_list` [arr]  
An array of strings containing WinTitles  
Multi_Clipboard will be disabled in any of the provided WinTitles  
WinTitle Docs: https://www.autohotkey.com/docs/v2/misc/WinTitle.htm  

***
## METHODS  
`toggle()`
Toggles the enable property on/off  
`Return` New enable state after the toggle  

***
## Why remake it?
It initially started out as a response to a post on the AHK subreddit.  
Rivisiting my old "multiple clipboard" script I wrote years ago was a flashback.  
It wasn't structured well and there were flaws in it.  

I decided to rewrite a small v2 mockup to share with the user.  
Originally, it wasn't very big.  
[Image of this script in its infancy.](https://i.imgur.com/gZJJrrO.png)  
However, I started getting into it and I kept modifying and adding stuff I never intended to include.  
Even recently I changed it from a "numpad OR number bar OR function keys" setup to a "enable any number set you want" setup.  

I also realized I was using quite a few different aspects of AHK's library.  
Creating guis. Adding controls and events.  
Dynamically creating hotkeys.  
String parsing.  
Object manipulation.  
Nested objects.  
Adding properties to adjust the script during operations so it can be changed by the user.  
Class structuring and avoidance of global space coding and variables.  
Not to mention all the different fucntions calls and object types used.  

I decided to start commenting out every line in hopes people might learn soemthing from the code if they decided to read through it.  
Or if they look up how a certain part of the code works.

***
## Changelog
1.0 initial upload
