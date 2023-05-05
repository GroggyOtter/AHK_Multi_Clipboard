# Multi_Clipboard for AHKv2

![Example of Multi_Clipboard GUI](https://i.imgur.com/fw1q83V.png)

## What is it?
A script to provide multi-clipboard support.  
![Number set image](https://i.imgur.com/mJlvE3T.png)  
It turns any/some/all of the number sets on the keyboard into extra clipboard slots.  
You have 32 extra clipboard slots if all number sets are used.  

You control them by setting/using different modifiers as ![action keys](https://i.imgur.com/6GyGpML.png).  
Example. If numpad clipboards are enabled, `copy_mod` is `^` ctrl, and `paste_mod` is `!` alt:  
ctrl+numpad5 will copy to slot Numpad5 and alt+numpad5 pastes whatever is stored in Numpad5.  

## Properties

### Number Set Properties  
* `use_pad`  
Enables number pad keys to be used as clipboards.

* `use_bar`  
Enables the number bar row to be used as clipboards.

* `use_f`  
Enables the Function number keys to be used as clipboards.
 
___ Modifier actions _____________________________________________________________________________  
copy_mod [str]      = Modifier that copies to a key  
paste_mod [str]     = Modifier that pastes from a key  
show_mod [str]      = Modifier shows contents of a key. Valid modifiers:  
                    = ! Alt   ^ Ctrl   + Shift   # Windows   < LeftSideMod   > RightSideMod  
 
___ Hotkey _______________________________________________________________________________________  
all_hotkey [str]    = A Hotkey to show contents of all clipboards  
 
___ Optional Properties __________________________________________________________________________  
enable [bool]       = true  -> Enables all hotkeys (does not override disable_list)  
                    = false -> Disables all hotkeys  
send_hotkey [bool]  = true  -> Native keystroke is included with the action remap  
                    = false -> Native keystroke is replaced by the action remap  
quick_view [bool]   = true  -> key down shows pop GUI and closes on key release  
                    = false -> Key press pops up GUI and it stays up until closed  
hide_empty [bool]   = true  -> Empty clipboards are omitted from display when shown  
                    = false -> Empty clipboards show with key headers and as <EMPTY>  
hide_binary [bool]  = true  -> Binary data clipboards are omitted from display when shown  
                    = false -> Binary data clipboards show with key headers and as <BINARY_DATA>  
show_max_char [num] = Max number of characters to show from each clipboard string  
                    = 0 disables max and uses the full string  
disable_list [arr]  = An array of strings containing WinTitles  
                    = Multi_Clipboard will be disabled in any of the provided WinTitles  
                    = WinTitle Docs: https://www.autohotkey.com/docs/v2/misc/WinTitle.htm  
___ METHODS ______________________________________________________________________________________  
toggle()            = Toggles the enable property on/off  
  Return            = The new enable state after toggle  
__________________________________________________________________________________________________  
Example: Enabling numpad, using ctrl for copy, alt for paste, and win for show:  
   All Numpad number keys act as individual clipboard slots  
   Pressing Ctrl+Numpad# will copy whatever has focus to a slot with that hotkey as a key  
   Pressing Alt+Numpad# will paste the contents  
   ANd Win+Numpad# will show the contents of that save in a GUI popup  
__________________________________________________________________________________________________  
## Why make it if it's a common script to make?  
It initially started out as a response to a post on the AHK subreddit.  
I revisited my old "multiple clipboard" script I wrote years ago (wow, I was really new to AHK when I wrote that!)  
I decided to rewrite a small v2 mockup to share with the user.  [Image of this script in its infancy.](https://i.imgur.com/gZJJrrO.png)  
However, I started getting into it and I kept modifying and adding stuff I never intended to include.  

Not only that, but I realized I was using quite a few things from AHK's library so I decided make it a purpose to comment each line in hopes anyone reading this will be able to learn from it.  
The code covers a LOT of different components.  
Creating guis. Adding controls and events.  
Dynamically creating hotkeys.  
String parsing.  
Object manipulation.  
Nested objects.  
Adding properties that can adjust the script on the fly/gives the user control over parts of the script.  
Class structuring and avoidance of global space coding and variables.  
Not to mention all the different fucntions calls and object types used.  
I just feel like it has a ton of different components to learn about.  

## Usage
Choose which [number sets](https://i.imgur.com/aKRtVQD.png) on the keyboard you want to use.  
Set `use_`
