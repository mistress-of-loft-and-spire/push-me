#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Menu, Tray, Icon, ico\offline.ico
Menu, Tray, Tip, Connecting...

#Persistent
#SingleInstance force


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;             SETUP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


global StatusText
global last_folder
global StatusIcon

IfNotExist, %A_WorkingDir%\settings.ini
	FileAppend, ###`n`r, %A_WorkingDir%\settings.ini
else
	IniRead, last_folder, %A_WorkingDir%\settings.ini, settings, last_folder

StatusText := "Connecting..."
StatusIcon := "main.ico"

tray()

;SetTimer, checkConnection, 3000

SetTimer, IconCarousel, 100

return



;;;;;;;;;;;;;;


tray()
{

Menu, Tray, Icon, ico\%StatusIcon%
Menu, Tray, Tip, %StatusText%

;Clear tray menu
Menu, Tray, NoStandard 
Menu, Tray, DeleteAll

Menu, Tray, add, %StatusText%, idle
Menu, Tray, disable, %StatusText%

Menu, Tray, Icon, %StatusText%, ico\main_i.ico,, 0

Menu, Tray, add ; separator

;Add repos

IniRead, temp_output, %A_WorkingDir%\settings.ini, repos

if (temp_output != ERROR or ) ;no repos present
{

	Loop, Parse, temp_output, `n
	{
		;get the repository name
		foldername = %A_LoopField%
		
		Stringgetpos,pos,foldername,=,L
		pos2 := pos + 2
		StringMid, folderpath, foldername, %pos2%
		StringLeft,foldername,foldername,%pos%
		
		;workaround for clearing the sub-menu items
		Menu, %foldername%, add
		Menu, %foldername%, DeleteAll
		
		;add sub-menu items
		Menu, %foldername%, add, Commit && Push Changes, push
			Menu, %foldername%, Icon, Commit && Push Changes, ico\check_i.ico,, 0
		Menu, %foldername%, add, Commit && Push Changes with Message, push_w_msg
			Menu, %foldername%, Icon, Commit && Push Changes with Message, ico\check_s_i.ico,, 0
		Menu, %foldername%, add, Pull Changes, pull
		
		Menu, %foldername%, add ; separator
		
		Menu, %foldername%, add, Create .gitignore, create_ignore
		
		Menu, %foldername%, add ; separator
		
		Menu, %foldername%, add, Open in Explorer, viewex
		Menu, %foldername%, add, View on GitHub, viewgh
		Menu, %foldername%, add, Open in Git Shell, viewsh
		
		Menu, %foldername%, add ; separator
		
		Menu, %foldername%, add, Remove, remove
		
		;create the repo sub-menu
		Menu, Tray, add, %foldername%, :%foldername%
		
		; Is it a fork?
		FileRead, configString, %folderpath%\.git\config
		
		StringSplit, configArray, configString, [
		Loop, %configArray0%
		{
			StringSplit, configTemp, configArray%a_index%, ]
			FoundPos := RegExMatch(configTemp1, "i)remote "".*""")
			If FoundPos = 1
			{
				
				If configTemp1 != remote "origin"
				{
					is_fork = true
				}
			}
			
		}
		
		If is_fork = true
			Menu, Tray, Icon, %foldername%, ico\fork_i.ico,, 0
		else
			Menu, Tray, Icon, %foldername%, ico\repo_i.ico,, 0

		is_fork = 
		
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



;;;;;;;;;;;MAIN MENU;;;;;;;;;;;


add:
FileSelectFolder, current_dir, *%last_folder%, 2, Select repository to sync
if current_dir !=
{
	file = %current_dir%\.git
	IfExist, %file%
	{
		;check if folder is already in repo list
		Loop
		{
			IniRead, temp_output, %A_WorkingDir%\settings.ini, repos, %A_Index%
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
			
			IniWrite, %current_dir%, %A_WorkingDir%\settings.ini, repos, %foldername%
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
	IniWrite, %last_folder%, %A_WorkingDir%\settings.ini, settings, last_folder
}
Return


create:
Return



;;;;;;;;;;;SUB-MENUS;;;;;;;;;;;


push:
IniRead, OutputVar, %A_WorkingDir%\settings.ini, repos, %A_ThisMenu%
Run, C:\Program Files\Git\bin\sh.exe --login -i -- %A_WorkingDir%\push.sh, %OutputVar%
Return


push_w_msg:
Return


pull:
IniRead, OutputVar, %A_WorkingDir%\settings.ini, repos, %A_ThisMenu%
Run, C:\Program Files\Git\bin\sh.exe --login -i -- %A_WorkingDir%\pull.sh, %OutputVar%
Return


create_ignore:
shellCmd = git pull;git add .;git commit -m "push-me commit on %A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%";git push;

MsgBox % RunGit(shellCmd, A_ThisMenu)
Return

RunGit(command, dir) {
	IniRead, dirVar, %A_WorkingDir%\settings.ini, repos, %dir%

	RunWait, %comspec% /c ""C:\Program Files\Git\bin\sh.exe" --login -c '%command%' >%A_ScriptDir%/temp.log", %dirVar%, Hide
	;RunWait, C:\Program Files\Git\bin\sh.exe --login -c '%command%' >%A_ScriptDir%/temp.log, %dirVar% ;, Hide

	FileRead, OutputVar, %A_ScriptDir%/temp.log

    return %OutputVar%
}

viewgh:
IniRead, OutputVar, %A_WorkingDir%\settings.ini, repos, %A_ThisMenu%
IniRead, Outputurl, %OutputVar%\.git\config, remote "origin", url
Run, %Outputurl%
Return


viewex:
IniRead, OutputVar, %A_WorkingDir%\settings.ini, repos, %A_ThisMenu%
Run, %OutputVar%
Return


viewsh:
IniRead, OutputVar, %A_WorkingDir%\settings.ini, repos, %A_ThisMenu%
Run, C:\Program Files\Git\bin\sh.exe --login -i, %OutputVar%
Return


remove:
IniDelete, %A_WorkingDir%\settings.ini, repos, %A_ThisMenu%
sortini()
tray()
Return



;;;;;;;;;;;MAIN MENU - Rest;;;;;;;;;;;


wincred:
Run, C:\Program Files\Git\bin\sh.exe --login -i -- %A_WorkingDir%\wincred.sh
Return


idle:
Return


Exit:
ExitApp


checkConnection:
connected_current := IsInternetConnected()

if connected_current != connected
{
	

	if connected_current
	{
		StatusIcon := "main.ico"
		StatusText := "Everything is up to date"
		tray()
	}
	else
	{
		StatusIcon := "offline.ico"
		StatusText := "Offline"
		tray()
	}
}

connected := connected_current
Return


IconCarousel:
ic++
curico = %A_WorkingDir%\ico\sync_i_%ic%.ico
Menu, Tray, Icon, %curico%
If ic = 6
 ic = 0
return


#F5::
Reload:
Reload
return



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; FUNCTIONS ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


sortini()
{
	;let's sort the repos A -> Z
	IniRead, OutputVarSection, %A_WorkingDir%\settings.ini, repos
	if OutputVarSection != ERROR  ; Successfully loaded.
	{
		Sort, OutputVarSection
		
		IniDelete, %A_WorkingDir%\settings.ini, repos
		IniWrite, %OutputVarSection%, %A_WorkingDir%\settings.ini, repos
		
		OutputVarSection =  ; Free the memory.
	}
}


IsInternetConnected()
{
  static sz := A_IsUnicode ? 408 : 204, addrToStr := "Ws2_32\WSAAddressToString" (A_IsUnicode ? "W" : "A")
  VarSetCapacity(wsaData, 408)
  if DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", &wsaData)
    return false
  if DllCall("Ws2_32\GetAddrInfoW", "wstr", "dns.msftncsi.com", "wstr", "http", "ptr", 0, "ptr*", results)
  {
    DllCall("Ws2_32\WSACleanup")
    return false
  }
  ai_family := NumGet(results+4, 0, "int")    ;address family (ipv4 or ipv6)
  ai_addr := Numget(results+16, 2*A_PtrSize, "ptr")   ;binary ip address
  ai_addrlen := Numget(results+16, 0, "ptr")   ;length of ip
  DllCall(addrToStr, "ptr", ai_addr, "uint", ai_addrlen, "ptr", 0, "str", wsaData, "uint*", 204)
  DllCall("Ws2_32\FreeAddrInfoW", "ptr", results)
  DllCall("Ws2_32\WSACleanup")
  http := ComObjCreate("WinHttp.WinHttpRequest.5.1")

  if (ai_family = 2 && wsaData = "131.107.255.255:80")
  {
    http.Open("GET", "http://www.msftncsi.com/ncsi.txt")
  }
  else if (ai_family = 23 && wsaData = "[fd3e:4f5a:5b81::1]:80")
  {
    http.Open("GET", "http://ipv6.msftncsi.com/ncsi.txt")
  }
  else
  {
    return false
  }
  http.Send()
  return (http.ResponseText = "Microsoft NCSI") ;ncsi.txt will contain exactly this text
}
