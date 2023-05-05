;___________________________________________________________________________________________________  
; Multi_Clipboard - A Customizable multi-clipboard script for AHKv2  
; Created by: GroggyOtter  
; Creation Date: 20230501  
; Github Link: https://github.com/GroggyOtter/AHK_Multi_Clipboard/  
; License: Unrestricted. Please keep this top section (title/namedat/github/lic) with the code
; ___ USAGE ________________________________________________________________________________________  
; Treats a any of the keyboards number sets (numpad, function keys, number row) as multiple   
; virtual clipboards that you can copy to, paste from, and even display their saved contents.  
; All key sets can be used.
;
; ___ PROPERTIES ___________________________________________________________________________________  
; use_pad [bool]      = true -> Enable numpad keys as extra clipboards  
; use_bar [bool]      = true -> Enable number bar keys as extra clipboards  
; use_f [bool]        = true -> Enable function keys as extra clipboards  
;  
; ___ Modifier actions _____________________________________________________________________________  
; copy_hotkey [str]   = Modifier that copies to a key  
; paste_hotkey [str]  = Modifier that pastes from a key  
; show_hotkey [str]   = Modifier shows contents of a key. Valid modifiers:  
;                     = ! Alt   ^ Ctrl   + Shift   # Windows   < LeftSideMod   > RightSideMod  
;  
; ___ Hotkey _______________________________________________________________________________________  
; all_hotkey [str]    = A Hotkey to show contents of all clipboards  
;  
; ___ Optional Properties __________________________________________________________________________  
; enable [bool]       = true  -> Enables all hotkeys (does not override disable_list)  
;                     = false -> Disables all hotkeys  
; send_hotkey [bool]  = true  -> Native keystroke is included with the action remap  
;                     = false -> Native keystroke is replaced by the action remap  
; quick_view [bool]   = true  -> key down shows pop GUI and closes on key release  
;                     = false -> Key press pops up GUI and it stays up until closed  
; hide_empty [bool]   = true  -> Empty clipboards are omitted from display when shown  
;                     = false -> Empty clipboards show with key headers and as <EMPTY>  
; hide_binary [bool]  = true  -> Binary data clipboards are omitted from display when shown  
;                     = false -> Binary data clipboards show with key headers and as <BINARY_DATA>  
; show_max_char [num] = Max number of characters to show from each clipboard string  
;                     = 0 disables max and uses the full string  
; disable_list [arr]  = An array of strings containing WinTitles  
;                     = Multi_Clipboard will be disabled in any of the provided WinTitles  
;                     = WinTitle Docs: https://www.autohotkey.com/docs/v2/misc/WinTitle.htm  
; ___ METHODS ______________________________________________________________________________________  
; toggle()            = Toggles the enable property on/off  
;   Return            = The new enable state after toggle  
;___________________________________________________________________________________________________  
; Example: Enabling numpad, using ctrl for copy, alt for paste, and win for show:  
;    All Numpad number keys act as individual clipboard slots  
;    Pressing Ctrl+Numpad# will copy whatever has focus to a slot with that hotkey as a key  
;    Pressing Alt+Numpad# will paste the contents  
;    ANd Win+Numpad# will show the contents of that save in a GUI popup  
;___________________________________________________________________________________________________  
class multi_clipboard {                                                                             ; Make a class to bundle our properties (variables) and methods (functions)
    #Requires AutoHotkey 2.0+                                                                       ; Always define ahk version
    static version      := '1.0'                                                                    ; Helps to track versions and what changes have been made
    
    ; USER PROPERTIES
    ; Choose number sets to use
    static use_pad      := 1                                                                        ; Enable/disable numpad keys
    static use_bar      := 0                                                                        ; Enable/disable number bar keys
    static use_f        := 0                                                                        ; Enable/disable function keys
    ; Action modifiers
    static copy_hotkey  := '^'                                                                      ; Modifier key to make a key copy
    static paste_hotkey := '!'                                                                      ; Modifier key to make a key paste
    static show_hotkey  := '#'                                                                      ; Modifier key to show key contents
    ; Script hotkeys
    static all_hotkey   := '^NumpadEnter'                                                           ; Hotkey to show all keys
    ; User preferences
    static enable       := 1                                                                        ; true -> disalbes all script hotkeys (give user full control of the hotkeys)
    static send_hotkey  := 0                                                                        ; true -> include sending hotkey's native keystroke
    static quick_view   := 0                                                                        ; true -> close GUI on key release
    static hide_empty   := 1                                                                        ; true -> omit empty clipboards from being shown
    static hide_binary  := 0                                                                        ; true -> omit clipboards with binary data from shown
    static show_max_char:= 0                                                                        ; Max chars to show from any clipboard, 0 is no limit
    static disable_list := ['ahk_exe exampleOfAnExeName.exe'                                        ; Array of WinTitles where Multi_Clipboard will be disabled
                           ,'PutTitleHere ahk_exe PutExeNameHere.exe ahk_class ClassNameGoesHere']  ; Full WinTitle example of a fake program
    
    ; USER METHODS
    static toggle() {                                                                               ; Toggles hotkeys on/off
        this.enable := !this.enable                                                                 ; Switch between on <-> off
        return this.enable                                                                          ; Return new state to caller
    }
    
    static __New() {                                                                                ; Run at script startup
        this.make_disable_group()                                                                   ; Create group of windows where hotkeys are disabled
        ,Hotif((*)=>this.enable && !WinActive('ahk_group ' this.disable_group))                     ; Conditions 
        ,obm := ObjBindMethod(this, 'show', '')                                                     ; Create the show all clipboards boundfunc
        ,Hotkey('*' this.all_hotkey, obm)                                                           ; Create show all hotkey using obm
        ,this.clip_dat := Map()                                                                     ; Initialize clip_dat map to store all clipboard data
        ,this.gui := 0                                                                              ; Initialize gui property
        ,this.mod_map := Map('copy' ,this.copy_hotkey                                               ; Make map for hotkey creation
                            ,'paste',this.paste_hotkey
                            ,'show' ,this.show_hotkey)
        ,this.verify_mod_map()                                                                      ; Warn user of any duplicate maps
        
        ; Hotkey generation
        this.backup()                                                                               ; Backup and clear clipboard
        ,empty := ClipboardAll()                                                                    ; Save empty ClipboardAll object for clip_dat initialization
        for _, key in ['bar', 'pad', 'f'] {                                                         ; Loop through each type of key set
            if (!this.use_%key%)                                                                    ;  If the 'use_' property of that set is false
                continue                                                                            ;   Continue to next set
            
            times := (key = 'f') ? 12 : 10                                                          ;  Get number of times to loop (keys in number set)
            ,prfx := (key = 'f') ? 'F' : (key = 'pad') ? 'Numpad' : ''                              ;  Get numset prefix
            
            loop times                                                                              ;  Loop once for each number in the set
                num  := (key = 'f') ? A_Index : A_Index - 1                                         ;   -1 to start at 0 except FuncKeys that start at 1
                ,this.clip_dat[prfx num] := {str:'', bin:empty}                                     ;   Initialize with an object for string and raw binary
                ,this.make_hotkey(num, prfx)                                                        ;   Create hotkey
        }
        HotIf()                                                                                     ; ALWAYS reset HotIf() after you're done using it
        ,this.restore()                                                                             ; Restore original clipbaord contents
    }
    
    static make_hotkey(num, prfx) {
        num_shift := Map(0,'Ins'    ,1,'End'    ,2,'Down'  ,3,'PgDn'  ,4,'Left'                     ; Used with numpad keys to create shift variants
                        ,5,'Clear'  ,6,'Right'  ,7,'Home'  ,8,'Up'    ,9,'PgUp')
        
        defmod := (this.send_hotkey ? '~*' : '*')                                                   ; Check if user wants to include the ~ modifier
        
        for method, hk_mod in this.mod_map {                                                        ; Loop through copy/paste/show methods and mods
            obm := ObjBindMethod(this, method, prfx num)                                            ;  Make BoundFunc to run when copy/paste/show pressed
            ,Hotkey('*' hk_mod prfx num, obm)                                                       ;  Creates copy/paste/show in both numpad and shift+numpad variants
            ,(prfx = 'numpad') ? Hotkey(defmod hk_mod prfx num_shift[num], obm) : 0                 ;  If numpad, make a shift-variant hotkey
        }
    }
    
    static make_disable_group() {                                                                   ; Creats a window group where script hotkeys are disabled
        this.disable_group := 'MULTI_CLIPBOARD_DISABLE_LIST'                                        ; Use a unique groupname (so it doesn't interfer with another)
        for _, id in this.disable_list                                                              ; Loop through the list of WinTitles IDs
            GroupAdd(this.disable_group, id)                                                        ;  Add each WinTitle to the group
    }
    
    static copy(index, *) {                                                                         ; Method to call when copying data
        this.backup()                                                                               ; Backup current clipboard contents
        ,SendInput('^c')                                                                            ; Send copy
        ,ClipWait(1, 1)                                                                             ; Wait up to 1 sec for clipboard to contain something
        ,this.clip_dat[index].bin := ClipboardAll()                                                 ; Save binary data to bin
        ,this.clip_dat[index].str := A_Clipboard                                                    ; Save string to str
        ,this.restore()                                                                             ; Restore original clipbaord contents
    }
    
    static paste(index, *) {                                                                        ; Method to call when pasting saved data
        this.backup()                                                                               ; Backup current clipboard contents
        ,A_Clipboard := this.clip_dat[index].bin                                                    ; Put saved data back onto clipboard
        ,SendInput('^v')                                                                            ; Paste
        loop 20                                                                                     ; Check if clipboard is in use up to 20 times
            Sleep(50)                                                                               ;  Wait 50ms each time and check again
        Until !DllCall('GetOpenClipboardWindow')                                                    ; Break when clipboard isn't in use
        this.restore()                                                                              ; Restore original clipbaord contents
    }
    
    static backup() {                                                                               ; Backup and clear clipboard
        this._backup := ClipboardAll()
        ,A_Clipboard := ''
    }
    
    static restore() {                                                                              ; Restore backup to clipboard
        A_Clipboard := this._backup
    }
    
    static show(index:='', hk:='', *) {                                                             ; Method to show contents of clip_dat
        str := ''                                                                                   ; String to display
        if (index != '')                                                                            ; If key not blank, index was specified
            str := this.format_line(index)                                                          ;  Get line from that index
        else                                                                                        ; Else if key was blank, get all clipboards
            for index in this.clip_dat                                                              ;  Loop through clip_dat
                str .= this.format_line(index)                                                      ;   Format each clipboard
        
        edit_max_char := 64000                                                                      ; Edit boxes have a max char of around 64000
        if (StrLen(str) > edit_max_char)                                                            ; If chars exceed that, it will error
            str := SubStr(str, 1, edit_max_char)                                                    ;  Keep only the first 64000 chars
        
        this.make_gui(Trim(str, '`n'))                                                              ; Trim new lines from text and make a gui to display str
        
        If this.quick_view                                                                          ; If quick view is enabled
            KeyWait(this.strip_mods(hk))                                                            ;  Halt code here until hotkey is released
            ,this.destroy_gui()                                                                     ;  Destroy gui after key release
        return
    }
    
    static format_line(index) {                                                                     ; Formats clipboard text for display
        dat := this.clip_dat[index]                                                                 ; Get clipboard data
        switch {
            case (dat.bin.Size = 0):                                                                ; If slot is empty
                if this.hide_empty                                                                  ;  And hide empty enabled
                    return                                                                          ;   Return nothing
                body := '<EMPTY>'                                                                   ;  Otherwise assign empty tag
            case StrLen(dat.str):                                                                   ; Or if data is text
                body := this.show_max_char                                                          ;   Check if there's a max char
                    ? SubStr(dat.str, 1, this.show_max_char)                                        ;    If yes, get that many chars
                    : dat.str                                                                       ;    Else use the full string
            default:                                                                                ; Default: binary data if not empty or string
                if this.hide_binary                                                                 ;  If hide binary enabled
                    return                                                                          ;   Return nothing
                body := '<BINARY DATA>'                                                             ;  Otherwise assign binary tag
                     .  '`n  Pointer: ' dat.bin.Ptr '`n  Size: ' dat.bin.Size                       ; And ptr/size info
        }
        header := ';===[' index ']============================================================'     ; Make header for clipboard data
        return header '`n`n' body '`n`n'                                                            ; Return built string
    }
    
    static make_gui(str) {                                                                          ; Create a gui to display text
        if this.HasOwnProp('gui')                                                                   ; Check if a gui already exists
            this.destroy_gui()                                                                      ; If yes, get rid of it
        
        ; Set default values
        m := 10                                                                                     ; Choose default margin size
        ,chr_w := 8                                                                                 ; Set a char width
        ,chr_h := 15                                                                                ; Set a char height
        ,strl := 1                                                                                  ; Track max str length
        ,strr := 1                                                                                  ; Track total str rows
        loop parse str, '`n', '`r'                                                                  ; Go through each line of the string
            n := StrLen(A_LoopField), (n > strl ? strl := n : 0)                                    ;  If length of str > strl, record new max
            , strr := A_Index                                                                       ;  And record current row (for max rows)
        
        ; Approximate how big the edit box should be
        w := (strl) * chr_w                                                                         ; Width = chars wide * char width
        ,h := (strr + 3) * chr_h                                                                    ; Height = Rows (+4 scrollbar/padding) * char height
        ,(h > A_ScreenHeight*0.7) ? h := A_ScreenHeight*0.7 : 0                                     ; Don't let height exceed 70% screen height
        ,(w > A_ScreenWidth*0.8) ? w := A_ScreenWidth*0.8 : 0                                       ; Don't let width exceed 80% screen width
        ,(w < 500) ? w := 500 : 0                                                                   ; Maintain a minimum width
        ,(h < 100) ? h := 100 : 0                                                                   ; Maintain a minimum height
        ,edt := {h:h, w:w}                                                                          ; Set edit box dimensions
        ,btn := {w:(edt.w - m) / 2, h:30}                                                           ; Set btn width to edit box width and 30 px high
        ,title := A_ScriptName                                                                      ; Set the title to show
        ,bg_col := '101010'                                                                         ; Background color (very dark gray)
        
        ; Make GUI
        goo := Gui()                                                                                ; Make main gui object
        ,goo.title := title                                                                         ; Set window title
        ,goo.MarginX := goo.MarginY := m                                                            ; Set default margins > Useful for spacing
        ,goo.BackColor := bg_col                                                                    ; Make main gui dark
        ,goo.OnEvent('Close', (*) => goo.Destroy())                                                 ; On gui close, destroy it
        ,goo.OnEvent('Escape', (*) => goo.Destroy())                                                ; On escape press, destroy it
        ,goo.SetFont('s10 cWhite Bold', 'Consolas')                                               ; Default font size, color, weight, and type
        
        ; Edit box
        opt := ' ReadOnly -Wrap +0x300000 -WantReturn -WantTab Background' bg_col                   ; Edit control options
        ,goo.edit := goo.AddEdit('xm ym w' edt.w ' h' edt.h opt, str)                               ; Add edit control to gui
        
        ; Copy btn
        goo.copy := goo.AddButton('xm y+' m ' w' btn.w ' h' btn.h, 'Copy To Clipboard')             ; Add an large close button
        ,goo.copy.OnEvent('Click', (*) => A_Clipboard := goo.edit.value)                            ; When it's clicked, destroy gui
        ,goo.copy.Focus()                                                                           ; Now close button the focused control
        
        ; Close btn
        goo.close := goo.AddButton('x+' m ' yp w' btn.w ' h' btn.h, 'Close')                        ; Add an large close button
        ,goo.close.OnEvent('Click', (*) => goo.Destroy())                                           ; When it's clicked, destroy gui
        ,goo.close.Focus()                                                                          ; Now close button the focused control
        
        ; Finish up
        obm := ObjBindMethod(this, "WM_MOUSEMOVE")                                                  ; Boundfunc to run with OnMessage
        ,OnMessage(0x200, obm)                                                                      ; When gui detects mouse movement (0x200), run boundfunc
        ,this.gui := goo                                                                            ; Save gui to class for later use
        ,this.gui.Show()                                                                            ; And show gui
    }
    
    ; https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-mousemove
    ; Allows click+drag movement on non-elements 
    static WM_MOUSEMOVE(wparam, lparam, msg, hwnd) {                                                ; Function that runs on gui mouse move
        static WM_NCLBUTTONDOWN := 0xA1                                                             ; Message for left clicking on a window's titlebar
        if (wparam = 1)                                                                             ; If Left Mouse is down
            PostMessage(WM_NCLBUTTONDOWN, 2,,, "ahk_id " hwnd)                                      ;  Tell windows left click is down on the title bar
    }
    
    static destroy_gui() {                                                                          ; Destroys current gui
        try this.gui.destroy()                                                                      ; Try suppresses errors if gui doesn't exist
    }
    
    static strip_mods(txt) {                                                                        ; Used to remove modifiers from hotkey strings
        loop parse '^!#+*<>~$'                                                                      ; Go through each modifier
            if SubStr(txt, -1) != A_LoopField                                                       ;  Last char can't match or the symbol is the literal key
                txt := StrReplace(txt, A_LoopField)                                                 ;   Otherwise remove it
        return txt                                                                                  ; Return neutered hotkey
    }
    
    static verify_mod_map() {                                                                       ; Warns user of duplicate key assignments
        for meth1, mod1 in this.mod_map                                                             ; Loop through mod_map once for base
            for meth2, mod2 in this.mod_map                                                         ;  Loop again for comparison
                if StrCompare(mod1, mod2) && !StrCompare(meth1, meth2)                              ;   If two modifiers match but keys don't
                    throw Error('Duplicate modifiers found in mod_map', A_ThisFunc                  ;    Throw an error to notify user
                            ,'`n' meth1 ':' mod1 '`n' meth2 ':' mod2)
    }
}
