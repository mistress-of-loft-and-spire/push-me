#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Persistent
#SingleInstance force


Menu, Tray, Icon, ico\main.ico
Menu, Tray, Tip, GitAutoPush



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;             SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


current_dir = C:\Users\voec\Documents\push-this

last_folder = 

IniRead, last_folder, %A_WorkingDir%\gap.ini, settings, last_folder

tray()
return



;;;;;;;;;;;;;;


tray()
{
;Clear tray menu
Menu, Tray, NoStandard 
Menu, Tray, DeleteAll


Menu, Tray, add, Everything is up to date, idle
Menu, Tray, disable, Everything is up to date

Menu, Tray, Icon, Everything is up to date, ico\main_i.ico,, 0

Menu, Tray, add ; separator

;Add repos

IniRead, temp_output, %A_WorkingDir%\gap.ini, repos

if (temp_output != ERROR or ) ;no repos added
{

	Loop, Parse, temp_output, `n
	{
		;get the repository name
		foldername = %A_LoopField%
		
		Stringgetpos,pos,foldername,=,L
		StringLeft,foldername,foldername,%pos%
		
		;workaround for clearing the sub-menu items
		Menu, %foldername%, add
		Menu, %foldername%, DeleteAll
		
		;add sub-menu items
		Menu, %foldername%, add, Commit && Push Changes, push
			Menu, %foldername%, Icon, Commit && Push Changes, ico\check_i.ico,, 0
		Menu, %foldername%, add, Commit && Push Changes with Message, push_m
			Menu, %foldername%, Icon, Commit && Push Changes with Message, ico\check_s_i.ico,, 0
		Menu, %foldername%, add, Pull Changes, pull
		
		Menu, %foldername%, add ; separator
		
		Menu, %foldername%, add, Create .gitignore, create
		
		Menu, %foldername%, add ; separator
		
		Menu, %foldername%, add, View on GitHub, viewgh
		Menu, %foldername%, add, Open in Explorer, viewex
		Menu, %foldername%, add, Open in Git Shell, viewsh
		
		Menu, %foldername%, add ; separator
		
		Menu, %foldername%, add, Remove, remove
		
		;create the repo sub-menu
		Menu, Tray, add, %foldername%, :%foldername%
			Menu, Tray, Icon, %foldername%, ico\repo_i.ico,, 0
		
	}
	
	Menu, Tray, add ; separator
}



;Add other stuff
Menu, Tray, add, Add Repository, add
	Menu, Tray, Icon, Add Repository, ico\plus_i.ico,, 0
Menu, Tray, add, Create new Repository, create
Menu, Tray, disable, Create new Repository

Menu, Tray, add ; separator
Menu, Tray, add, Cache GitHub Password, wincred

Menu, Tray, add ; separator
Menu, Tray, add, Reload
Menu, Tray, add, Exit
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




add:
FileSelectFolder, current_dir, *%last_folder%, 2, Select repository to add
if current_dir !=
{
	file = %current_dir%\.git
	IfExist, %file%
	{
		;check if folder is already in repo list
		Loop
		{
			IniRead, temp_output, %A_WorkingDir%\gap.ini, repos, %A_Index%
			repo_index := A_Index
			
			if temp_output = ERROR
			{
				temp_output = OK
				Break
			}
			if temp_output = %current_dir% 
			{
				temp_output = EXISTS
				Break
			}
		}
		
		;MsgBox, %repo_index%
		
		;if value not yet exists ->
		if temp_output = OK
		{
			foldername = %current_dir%
			
			Stringgetpos,pos,foldername,\,R
			pos+=1
			Stringtrimleft,foldername,foldername,%pos%
			
			IniWrite, %current_dir%, %A_WorkingDir%\gap.ini, repos, %foldername%
			sortini()
			tray()
		}
		else
		{
			MsgBox, This repository has already been added.
		}
	}
	else
	{
		MsgBox, This directory does not appear to be a git repository.
	}
	last_folder := current_dir
	IniWrite, %last_folder%, %A_WorkingDir%\gap.ini, settings, last_folder
}
Return



remove:
IniDelete, %A_WorkingDir%\gap.ini, repos, %A_ThisMenu%
sortini()
tray()
Return



create:
Return


push:
IniRead, OutputVar, %A_WorkingDir%\gap.ini, repos, %A_ThisMenu%
Run, C:\Program Files\Git\bin\sh.exe --login -i -- %A_WorkingDir%\push.sh, %OutputVar%
Return


push_m:
Return


pull:
IniRead, OutputVar, %A_WorkingDir%\gap.ini, repos, %A_ThisMenu%
Run, C:\Program Files\Git\bin\sh.exe --login -i -- %A_WorkingDir%\pull.sh, %OutputVar%
Return


viewgh:
IniRead, OutputVar, %A_WorkingDir%\gap.ini, repos, %A_ThisMenu%
IniRead, Outputurl, %OutputVar%\.git\config, remote "origin", url
Run, %Outputurl%
Return

viewex:
IniRead, OutputVar, %A_WorkingDir%\gap.ini, repos, %A_ThisMenu%
Run, %OutputVar%
Return

viewsh:
IniRead, OutputVar, %A_WorkingDir%\gap.ini, repos, %A_ThisMenu%
Run, C:\Program Files\Git\bin\sh.exe --login -i, %OutputVar%
Return

wincred:
Run, C:\Program Files\Git\bin\sh.exe --login -i -- %A_WorkingDir%\wincred.sh
Return



idle:
Return



Exit:
ExitApp




Reload:
Reload
return


sortini()
{
	;let's sort the repos A -> Z
	IniRead, OutputVarSection, %A_WorkingDir%\gap.ini, repos
	if OutputVarSection != ERROR  ; Successfully loaded.
	{
		Sort, OutputVarSection
		
		IniDelete, %A_WorkingDir%\gap.ini, repos
		IniWrite, %OutputVarSection%, %A_WorkingDir%\gap.ini, repos
		
		OutputVarSection =  ; Free the memory.
	}
}

