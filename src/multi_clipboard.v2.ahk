;===================================================================================================
; Multi_Clipboard
; GroggyOtter - 20230502
;===================================================================================================
; Customizeable multi-clipboard script
; Allows number bar, numpad, or function keys to be used.
; Modifier keys are used to either copy, paste, or view a key's clipboard
; 
; === Usage ========================================================================================
; Treats a numberset as multiple virtual clipboard that you can copy to, paste from, and display
;   Example:input_mode is 1, copy_hotkey is ^, paste_hotkey is <!, show_hotkey is #
;     Control+Numpad5 saves to clipboard 5
;     LeftALt+Numpad5 pastes whatever is on clipboard 5 (But RightAlt does not work)
;     Win+Numpad5 displays a gui showing the conents, if any, saved to clipboard 5
; 
; === Properties ===================================================================================
; input_mode      = Determines if numpad, the number bar, or function keys are used
;     numbar  | 0 = Top row 0-9 are used
;     numpad  | 1 = Numpad0 - Numpad9 are used
;     func    | 2 = F1-F12 are used
; quick_view      = If true, key down shows pop GUI and closes on key release
;
; === Hotkey Properties ============================================================================
; copy_hotkey     = Modifier that assigns copying to a key
; paste_hotkey    = Modifier that assigns pasting from a key
; show_hotkey     = Modifier that shows current contents of a key
; all_hotkey      = Hotkey that shows contents of all clipboards
;                 = Modifier keys: Alt !  Shift +  Ctrl ^  Windows #  LeftSideMod <  RightSideMod >
;===================================================================================================
class multi_clipboard {                                                                             ; Make a class to bundle our properties (variables) and methods (functions)
    #Requires AutoHotkey 2.0+                                                                       ; Always define ahk version
    
    ; User settings
    static input_mode   := 1                                                                        ; Set numberset to use: 0 = 0-9, 1 = Numpad0-Numpad9, 2 = F1-F12
    static quick_view   := 0                                                                        ; Set to true to close clipview on key release
    
    static copy_hotkey  := '^'                                                                      ; Modifier key to make a key copy
    static paste_hotkey := '!'                                                                      ; Modifier key to make a key paste
    static show_hotkey  := '#'                                                                      ; Modifier key to show key contents
    static all_hotkey   := '^NumpadEnter'                                                           ; Hotkey to show all keys
    
    static input_mode_str => !this.input_mode ? 'Function' 
                        : this.input_mode = 1 ? 'Numpad'
                        : 'Number Bar'
    static __New() {                                                                                ; Run at script startup
        this.clip_dat := Map()                                                                      ; Create clip_dat map to store all clipboard data
        this.gui := 0                                                                               ; Initialize gui
        this.input_mode := this.set_input_mode()
        
        this.mod_map := Map('copy' ,this.copy_hotkey                                                ; Make map for hotkey creation
                        ,'paste',this.paste_hotkey
                        ,'show' ,this.show_hotkey)
        this.verify_mod_map()                                                                       ; Warn user of any duplicate maps
        
        obm := ObjBindMethod(this, 'show', '')                                                      ; Create a show all boundfunc to fire on keypress
        ,Hotkey('*' this.all_hotkey, obm)                                                           ; Create hotkey with obm
        
        times := this.input_mode = 2 ? 12 : 10                                                      ; Set loop to 10 times or 12 if function mode
        loop times {                                                                                ; Loop once for each key number
            num := A_Index - (this.input_mode = 2 ? 0 : 1)                                          ; Minus 1 for non function keys so they start at 0
            ,prfx := !this.input_mode ? '' : (this.input_mode = 1) ? 'Numpad' : 'F'                 ; Set prefix > 0 = none, 1 = NumPad, 2 = F
            ,this.clip_dat[num] := {str:'',bin:Buffer(0)}                                           ; Initialize with an object for string and binary
            ,this.make_hotkey(num, prfx)                                                            ; Create hotkey
        }
    }
    
    static set_input_mode() {                                                                       ; Converts text input_mode to number
        im := this.input_mode                                                                       ; Shorten b/c don't wanna type this.input_mode repeatedly
        return IsNumber(im) ? this.input_mode                                                       ; If number, all good
            : InStr(im, 'f') ? 2                                                                    ; only function has an f
            : InStr(im, 'p') ? 1                                                                    ; only numpad has a p
            : 0                                                                                     ; else default to number bar
    }
    
    static make_hotkey(num, prfx) {
        num_shift := Map(0,'Ins'    ,1,'End'    ,2,'Down'  ,3,'PgDn'  ,4,'Left'                     ; Used with numpad keys to create shift variants
                        ,5,'Clear'  ,6,'Right'  ,7,'Home'  ,8,'Up'    ,9,'PgUp')
        
        for method, hk_mod in this.mod_map {                                                        ; Loop through copy/paste/show methods and mods
            obm := ObjBindMethod(this, method, num)                                                 ; Make BoundFunc to run when copy/paste/show pressed
            ,Hotkey('*' hk_mod prfx num, obm)                                                       ; Creates copy/paste/show in both numpad and shift+numpad variants
            ,(this.input_mode = 1) ? Hotkey('*' hk_mod prfx num_shift[num], obm) : 0                ; If numpad, make a shift variant hotkey
        }
    }
    
    static copy(index, *) {                                                                         ; Method to call when copying data
        bak := ClipboardAll()                                                                       ; Backup current clipboard contents
        ,A_Clipboard := ''                                                                          ; Clear clipboard
        ,SendInput('^c')                                                                            ; Send copy
        ,ClipWait(1, 1)                                                                             ; Wait up to 1 sec for clipboard to contain something
        ,this.clip_dat[index].bin := ClipboardAll()                                                 ; Save string/bin data to clip_dat
        ,this.clip_dat[index].str := A_Clipboard                                                    ; Save string/bin data to clip_dat
        ,A_Clipboard := bak                                                                         ; Finally, restore the original clipboard contents
    }
    
    static paste(index, *) {                                                                        ; Method to call when pasting saved data
        bak := ClipboardAll()                                                                       ; Backup current clipboard contents
        ,A_Clipboard := this.clip_dat[index].bin                                                    ; Put saved data back onto clipboard
        ,SendInput('^v')                                                                            ; Paste
        loop 10                                                                                     ; Wait up to 1 second for clipboard to not be in use
            Sleep(100)
        Until !DllCall('GetOpenClipboardWindow')                                                    ; Break if clipboard not in use
        A_Clipboard := bak                                                                          ; Finally, restore the original clipboard contents
    }
    
    static show(index:='', hk:='', *) {                                                             ; Method to show contents of clip_dat
        str := ''                                                                                   ; String to display
        if (index != '')                                                                            ; If key not blank, clipboard was specified
            str .= this.format_line(index)                                                          ; Get that key's clipboard info
        else                                                                                        ; Else if key was blank, get all clipboards
            for index in this.clip_dat                                                              ; Loop through clip_dat
                str .= this.format_line(index) '`n`n'                                               ; Format each clipboard
        
        edit_max_char := 64000
        if (StrLen(str) > edit_max_char)
            str := SubStr(str, 1, edit_max_char)
        
        this.make_gui(RTrim(str, '`n'))                                                             ; Trim text and make a gui to display it
        
        If this.quick_view                                                                          ; If quick view is enabled
            KeyWait(this.strip_mods(hk))                                                            ; Halt code here until hotkey is released
            ,this.destroy_gui()                                                                     ; Destroy gui after key release
        return
    }
    
    static format_line(index) {                                                                     ; Formats clipboard text for display
        switch this.input_mode {                                                                    ; Get key type using input_mode
            case 0: typ := 'Number '
            case 1: typ := 'Numpad'
            case 2: typ := 'F'
        }
        dat := this.clip_dat[index]                                                                 ; Get clipboard data
        switch {
            case (dat.bin.Size = 0) : body := '<EMPTY>'                                             ; If var is empty, mark it
            case StrLen(dat.str)    : body := dat.str                                               ; If data contains text, use it
            default:                  body := '<BINARY DATA>`n  Pointer: ' dat.bin.Ptr              ; Else get binary data info
                                        .  '`n  Size: ' dat.bin.Size
        }
        bar := '================================================================================'   ; Separator
        str := ';=[' typ  index ']' bar '`n`n'                                                      ; Make text a little more sexy
        return str body
    }
    
    static make_gui(str) {                                                                          ; Create a gui to display text
        if this.HasOwnProp('gui')                                                                   ; Check if a gui already exists
            this.destroy_gui()                                                                      ; If yes, get rid of it
        
        ; Set default values
        m := 10                                                                                     ; Choose default margin size
        ,chr_w := 8                                                                                 ; Set a char width
        ,chr_h := 15                                                                                ; Set a char height
        ,strl := 0                                                                                  ; Track max str length
        loop parse str, '`n', '`r'                                                                  ; Go through each line of the string
            n := StrLen(A_LoopField), (n > strl ? strl := n : 0), strr := A_Index                   ; If length of str > strl, record new max
        
        w := (strl) * chr_w                                                                         ; Width = chars wide * char width
        ,h := (strr + 2) * chr_h                                                                    ; Height = Rows (+4 scrollbar/padding) * char height
        ,(h > A_ScreenHeight*0.7) ? h := A_ScreenHeight*0.7 : 0                                     ; Don't let height exceed 70% screen height
        ,(w > A_ScreenWidth*0.8) ? w := A_ScreenWidth*0.8 : 0                                       ; Don't let width exceed 80% screen width
        ,edt := {h:h, w:w}                                                                          ; Set edit box dimensions
        ,btn := {w:(edt.w - m) / 2, h:30}                                                           ; Set btn width to edit box width and 30 px high
        ,title := this.input_mode_str ' Keys - ' A_ScriptName                                       ; Set the title to show
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
        goo.close := goo.AddButton('x+' m ' yp w' btn.w ' h' btn.h, 'Close')                         ; Add an large close button
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
            PostMessage(WM_NCLBUTTONDOWN, 2,,, "ahk_id " hwnd)                                      ; Tell windows left click is down on the title bar
    }
    
    static destroy_gui() {                                                                          ; Destroys current gui
        try this.gui.destroy()                                                                      ; Try suppresses errors if gui doesn't exist
    }
    
    static strip_mods(txt) {                                                                        ; Used to remove modifiers from hotkey strings
        loop parse '^!#+*<>~$'                                                                      ; Go through each modifier
            if SubStr(txt, -1) != A_LoopField                                                       ; Last char can't match or the symbol is the literal key
                txt := StrReplace(txt, A_LoopField)                                                 ; Otherwise remove it
        return txt                                                                                  ; Return neutered hotkey
    }
    
    static verify_mod_map() {                                                                       ; Warns user of duplicate key assignments
        for meth1, mod1 in this.mod_map                                                             ; Loop through mod_map once for base
            for meth2, mod2 in this.mod_map                                                         ; Loop again for comparison
                if StrCompare(mod1, mod2) && !StrCompare(meth1, meth2)                              ; If two modifiers match but keys don't
                    throw Error('Duplicate modifiers found in mod_map', A_ThisFunc                  ; Throw an error to notify user
                            ,'`n' meth1 ':' mod1 '`n' meth2 ':' mod2)
    }
}
