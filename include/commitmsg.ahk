#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Menu, Tray, Icon, ..\ico\main_i.ico

#Persistent
#SingleInstance force


WinGetPos tsk_x, tsk_y, tsk_w, tsk_h, ahk_class Shell_TrayWnd
gui_w = 500
gui_h = 230
gui_x = 130
gui_y = 130
if tsk_w > %tsk_h% ;Taskbar is wide aka on top or bottom
{
	gui_x := A_ScreenWidth - gui_w - 20
	if(tsk_y > 10)
		gui_y := A_ScreenHeight - tsk_h - gui_h - 25 - 20
	else
		gui_y := tsk_h + 20
}
else             ;Taskbar is high aka on left or right
{ 
	gui_y := A_ScreenHeight - gui_h -25 - 20
	if(tsk_x > 10)
		gui_x := A_ScreenWidth - tsk_w - gui_w - 20
	else
		gui_x := tsk_w + 20
}

GUI, 2:+ToolWindow
GUI, 2:hide
Gui, 1:+Owner2

Gui -MinimizeBox -Resize +OwnDialogs +AlwaysOnTop
Gui, Color, white
gui, font, s10, Arial

Gui, Add, Edit, x110 y34 w352 h22 vSummary gSummary_c, 
Gui Add, Text, x35 yp3 w70 h20, Summary

Gui, Add, Edit, x110 yp28 w352 h56 vDescription, 
Gui Add, Text, x35 yp3 w70 h20, Description

Gui Add, Text, x110 yp62 w400 h20 cf35b41 +hidden vValid_path, The commit summary should not be longer than 50 characters.

listview_h := gui_h - 65
Gui Add, ListView, Disabled x0 y%listview_h% w500 h90 -E0x200

gui, font, s10 cb0ccf1
global Add
Gui Add, Text, x270 yp24 w110 h20 Right +BackgroundTrans vAdd gAdd_c, Commit && Push
gui, font, s10 c418ff3
global Close
Gui Add, Text, x400 yp0 w60 h20 Right +BackgroundTrans vCancel gCancel_c, Cancel

Gui Show, x%gui_x% y%gui_y% w%gui_w% h%gui_h%, Add Repository


global active_hover
global Path_is_valid

OnMessage(0x200, "Hover")



return

Summary_c:
Gui, Submit , NoHide
Path_is_valid = false

If Summary !=
{
	If StrLen(Summary) > 50
	{
		GuiControl, Show, Valid_path
		GuiControl,, Valid_path, The summary should not be longer than 50 characters.
		GuiControl, Hide, Add
		Gui, font, c418ff3
		GuiControl, Font, Add
		GuiControl, Show, Add
		Path_is_valid = true
	}
	else
	{
		GuiControl, Hide, Valid_path
		GuiControl, Hide, Add
		Gui, font, c418ff3
		GuiControl, Font, Add
		GuiControl, Show, Add
		Path_is_valid = true
	}
}
else
{
	GuiControl, Show, Valid_path
	GuiControl,, Valid_path, Please enter a commit summary.
	GuiControl, Hide, Add
	gui, font, cb0ccf1
	GuiControl, Font, Add
	GuiControl, Show, Add
}
Return

Browse_c:
	Gui +OwnDialogs
	Gui, Submit , NoHide
	Path := RegExReplace(Path, "\\$") 

	IfExist, %Path%
		last_folder = %Path%
	else
		IniRead, last_folder, %A_WorkingDir%\settings.ini, settings, last_folder

	IfNotExist, %last_folder%
		last_folder = %A_WorkingDir%

	FileSelectFolder, current_dir, *%last_folder%, 2, Select repository to add

	IfExist, %current_dir%
	{
		GuiControl,, Path, %current_dir%
		IniWrite, %current_dir%, %A_WorkingDir%\settings.ini, settings, last_folder
	}
Return

~NumpadEnter::
~Enter::
Gui, +LastFound
IfWinActive
	GoSub, Add_c
return

Add_c:
If Path_is_valid = true
{
	Path := RegExReplace(Path, "\\$") 
	
	foldername = %Path%
			
	Stringgetpos,pos,foldername,\,R
	pos+=1
	Stringtrimleft,foldername,foldername,%pos%
			
	IniWrite, %Path%, %A_WorkingDir%\settings.ini, repos, %foldername%

	sortini()
	Goto, GuiClose
}
Return

#F5::
Reload

Cancel_c:
GuiEscape:
GuiClose:
    ExitApp



Hover(wParam, lParam, Msg) {


MouseGetPos, , , , control
GuiControlGet c_label, Name, %control%

hover_elements = Cancel,Add,Browse

Loop, Parse, hover_elements, `,
{
	IfEqual, A_LoopField, Add
	{
		If Path_is_valid != true
			Continue
	}
    IfEqual, active_hover, %A_LoopField%
	{
		IfNotEqual, c_label, %A_LoopField%
		{
			GuiControl, Hide, %A_LoopField%
			gui, font, c418ff3 ;418ff3   0271AC
			GuiControl, Font, %A_LoopField%
			GuiControl, Show, %A_LoopField%
			active_hover = 
		}
	}
	else IfEqual, c_label, %A_LoopField%
	{
		GuiControl, Hide, %A_LoopField%
		gui, font, c005282 ;418ff3   0271AC
		GuiControl, Font, %A_LoopField%
		GuiControl, Show, %A_LoopField%
		active_hover = %A_LoopField%
	}
}

}


sortini()
{
	;let's sort the repos A -> Z
	IniRead, OutputVarSection, %A_WorkingDir%\settings.ini, repos
	if OutputVarSection != ERROR  ; Successfully loaded.
	{
		Sort, OutputVarSection
		
		IniDelete, %A_WorkingDir%\settings.ini, repos
		IniWrite, %OutputVarSection%, %A_WorkingDir%\settings.ini, repos
	}
	OutputVarSection =  ; Free the memory.
}