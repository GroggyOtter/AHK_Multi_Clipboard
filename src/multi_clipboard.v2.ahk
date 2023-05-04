;===================================================================================================
; Multi_Clipboard
; Created by: GroggyOtter
; Creation Date: 20230501
;===================================================================================================
; A Customizable multi-clipboard script.
; Allows number bar, numpad, and/or function keys to be used.
; Modifier keys are used to copy, paste, or view a key's clipboard
; 
; === Usage ========================================================================================
; Treats a any of the keyboards number sets (numpad, function keys, number row) as multiple 
; virtual clipboards that you can copy to, paste from, and even display their saved contents.
; All keys can be used
; 
; Example: Enabling numpad, using ctrl for copy, alt for paste, and win for show:
;    All Numpad number keys act as individual clipboard slots
;    Pressing Ctrl+Numpad# will copy whatever has focus to a slot with that hotkey as a key
;    Pressing Alt+Numpad# will paste the contents
;    ANd Win+Numpad# will show the contents of that save in a GUI popup
; 
; === Properties ===================================================================================
; use_numpad [bool]  = true  -> numpad keys are used as extra clipboards
; use_bar [bool]     = true  -> number bar keys are used as extra clipboards
; use_f [bool]       = true  -> Function keys are used as extra clipboards
;
; === Hotkey Properties ============================================================================
; all_hotkey [str]   = A Hotkey to show contents of all clipboards
; copy_hotkey [str]  = Modifier that copies to a key
; paste_hotkey [str] = Modifier that pastes from a key
; show_hotkey [str]  = Modifier shows contents of a key. Valid modifiers:
;                    = ! Alt   ^ Ctrl   + Shift   # Windows   < LeftSideMod   > RightSideMod
;
; === Optional Properties ==========================================================================
; quick_view [bool]  = true  -> key down shows pop GUI and closes on key release
;                    = false -> Key press pops up GUI and it stays up until closed
; hide_empty [bool]  = true  -> Empty clipboards are omitted from display when shown
;                    = false -> Empty clipboards show with key headers and as <EMPTY>
; hide_binary [bool] = true  -> Binary data clipboards are omitted from display when shown
;                    = false -> Binary data clipboards show with key headers and as <BINARY_DATA>
; disable_list [arr] = An array of strings containing WinTitles
;                    = Multi_Clipboard will be disabled in any of the provided WinTitles
;                    = WinTitle Docs: https://www.autohotkey.com/docs/v2/misc/WinTitle.htm
;
;===================================================================================================
class multi_clipboard {                                                                             ; Make a class to bundle our properties (variables) and methods (functions)
    #Requires AutoHotkey 2.0+                                                                       ; Always define ahk version
    static version      := '1.0'                                                                    ; Helps to track versions and what changes have been made
    
    ; User settings
    static use_pad      := 1                                                                        ; Enable/disable numpad keys
    static use_bar      := 1                                                                        ; Enable/disable number bar keys
    static use_f        := 1                                                                        ; Enable/disable function keys
    
    static copy_hotkey  := '^'                                                                      ; Modifier key to make a key copy
    static paste_hotkey := '!'                                                                      ; Modifier key to make a key paste
    static show_hotkey  := '#'                                                                      ; Modifier key to show key contents
    static all_hotkey   := '^NumpadEnter'                                                           ; Hotkey to show all keys
    
    static quick_view   := 0                                                                        ; Set to true to close GUI on key release
    static hide_empty   := 1                                                                        ; Set to true to omit empty clipboards from being shown
    static hide_binary  := 1                                                                        ; Set to true to omit clipboards with binary data from being shown
    static disable_list := ['ahk_exe MakeBelieveProgramName.exe'                                    ; Array of WinTitles where Multi_Clipboard will be disabled
                        ,'PutTitleHere ahk_exe PutExeNameHere.exe ahk_class AndClassNameHere']   ; Full WinTitle example for user
    
    static __New() {                                                                                ; Run at script startup
        this.make_disable_group()
        ,obm := ObjBindMethod(this, 'show', '')                                                     ; Create a show all boundfunc to fire on keypress
        ,HotIfWinNotactive('ahk_group ' this.group_name)                                            ; Set HotIf to disable hotkey in specified programs
        ,Hotkey('*' this.all_hotkey, obm)                                                           ; Create show all hotkey using obm
        ,this.clip_dat := Map()                                                                     ; Create main clip_dat map to store clipboard data
        ,this.gui := 0                                                                              ; Initialize gui property
        ,this.mod_map := Map('copy' ,this.copy_hotkey                                               ; Make map for hotkey creation
                            ,'paste',this.paste_hotkey
                            ,'show' ,this.show_hotkey)
        ,this.verify_mod_map()                                                                      ; Warn user of any duplicate maps
        ,this.backup()                                                                              ; Backup clipboard to original contents
        ,empty := ClipboardAll()                                                                    ; Save empty ClipboardAll object for clip_dat initialization
        
        for _, key in ['bar', 'pad', 'f'] {                                                         ; Loop through each type of key set
            if (!this.use_%key%)                                                                    ;  If that set is false
                continue                                                                            ;  Continue to next set
            
            times := (key = 'f') ? 12 : 10                                                          ;  Get number of keys in set
            ,prfx := (key = 'f') ? 'F' : (key = 'pad') ? 'Numpad' : ''                              ;  Get numset prefix
            
            loop times                                                                              ;  Loop once for each number in the set
                num  := (key = 'f') ? A_Index : A_Index - 1                                         ;   -1 to start at 0 except FuncKeys that start at 1
                ,this.clip_dat[prfx num] := {str:'', bin:empty}                                     ;   Initialize with an object for string and raw binary
                ,this.make_hotkey(num, prfx)                                                        ;   Create hotkey
        }
        HotIf()                                                                                     ; ALWAYS reset HotIf() after you've used it
        this.restore()                                                                              ; Restore clipboard to original contents
    }
    
    static make_hotkey(num, prfx) {
        num_shift := Map(0,'Ins'    ,1,'End'    ,2,'Down'  ,3,'PgDn'  ,4,'Left'                     ; Used with numpad keys to create shift variants
                        ,5,'Clear'  ,6,'Right'  ,7,'Home'  ,8,'Up'    ,9,'PgUp')
        
        for method, hk_mod in this.mod_map {                                                        ; Loop through copy/paste/show methods and mods
            obm := ObjBindMethod(this, method, prfx num)                                            ;  Make BoundFunc to run when copy/paste/show pressed
            ,Hotkey('*' hk_mod prfx num, obm)                                                       ;  Creates copy/paste/show in both numpad and shift+numpad variants
            ,(prfx = 'numpad') ? Hotkey('*' hk_mod prfx num_shift[num], obm) : 0                    ;  If numpad, make a shift variant hotkey
        }
    }
    
    static make_disable_group() {
        this.group_name := 'MULTI_CLIPBOARD_DISABLE_LIST'
        for _, id in this.disable_list
            GroupAdd(this.group_name, id)
    }
    
    static copy(index, *) {                                                                         ; Method to call when copying data
        this.backup()                                                                               ; Backup current clipboard contents
        ,SendInput('^c')                                                                            ; Send copy
        ,ClipWait(1, 1)                                                                             ; Wait up to 1 sec for clipboard to contain something
        ,this.clip_dat[index].bin := ClipboardAll()                                                 ; Save binary data to bin
        ,this.clip_dat[index].str := A_Clipboard                                                    ; Save string to str
        ,this.restore()                                                                             ; Restore clipboard to original contents
    }
    
    static paste(index, *) {                                                                        ; Method to call when pasting saved data
        this.backup()                                                                               ; Backup current clipboard contents
        ,A_Clipboard := this.clip_dat[index].bin                                                    ; Put saved data back onto clipboard
        ,SendInput('^v')                                                                            ; Paste
        loop 10                                                                                     ; Wait up to 1 second for clipboard to not be in use
            Sleep(100)                                                                              ;  Wait 100ms and check again
        Until !DllCall('GetOpenClipboardWindow')                                                    ; And break if clipboard not in use
        this.restore()                                                                              ; Restore clipboard to original contents
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
            case (dat.bin.Size = 0) :                                                               ; If slot is empty
                if this.hide_empty                                                                  ; And hide empty enabled
                    return                                                                          ; Return nothing
                body := '<EMPTY>'                                                                   ; Otherwise assign empty tag
            case StrLen(dat.str)    : body := dat.str                                               ; If data contains text, use it
            default:                                                                                ; Binary data is all that it can be
                if this.hide_binary                                                                 ; If hide binary enabled
                    return                                                                          ; Return nothing
                body := '<BINARY DATA>'                                                             ; Otherwise assign binary tag
                    .  '`n  Pointer: ' dat.bin.Ptr '`n  Size: ' dat.bin.Size                       ; And ptr/size info
        }
        
        str := '`n`n;=[' index ']'                                                                  ; Make header for clipboard data
            . '================================================================================'
            . '`n`n'
        return str body
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
            n := StrLen(A_LoopField), (n > strl ? strl := n : 0), strr := A_Index                   ;  If length of str > strl, record new max
        
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
