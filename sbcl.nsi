!include MUI2.nsh

!system `wine src/runtime/sbcl.exe --core output/sbcl.core --noinform --non-interactive --eval '(format t "~a-~a" (lisp-implementation-version) (string-downcase (machine-type)))' > /tmp/ver.txt`
!define /file VER /tmp/ver.txt

!system `wine src/runtime/sbcl.exe --core output/sbcl.core --noinform --non-interactive --eval '(format t "~a (~a)" (lisp-implementation-version) (machine-type))' > /tmp/ver.txt`
!define /file FULL_VER /tmp/ver.txt

!define PRODUCT "Steel Bank Common Lisp"

!define MUI_PRODUCT "${PRODUCT} ${FULL_VER}"
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${PRODUCT}"
!define MUI_FILE "sbcl"
!define MUI_ABORTWARNING
!define MUI_LICENSEPAGE_CHECKBOX

Name "${MUI_PRODUCT}"
OutFile "sbcl-${VER}-windows-binary.exe"
InstallDir "$PROGRAMFILES64\${PRODUCT}"
InstallDirRegKey HKLM "Software\${PRODUCT}" ""
XPStyle On
RequestExecutionLevel user
CRCCheck On
SetCompressor /final /solid lzma

Var StartMenuFolder

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "COPYING"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Section ""
	SetOutPath "$INSTDIR"

	File output\sbcl.core
	File src\runtime\sbcl.exe
	File ..\quasi-msys2\root\ucrt64\bin\zlib1.dll

	SetOutPath $INSTDIR\contrib
	File obj\sbcl-home\contrib\*.*

	WriteRegStr HKLM "Software\${PRODUCT}" "" $INSTDIR

	!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
	CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\sbcl.lnk" "$INSTDIR\sbcl.exe" '--core "$INSTDIR\sbcl.core"'
	!insertmacro MUI_STARTMENU_WRITE_END

	Push $INSTDIR
	Call AddToPath

	WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
	RMDir /r "$INSTDIR\*.*"
	Delete "$INSTDIR\Uninstall.exe"

	RMDir "$INSTDIR"

	!insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
	Delete "$SMPROGRAMS\$StartMenuFolder\*.*"
	RMDir  "$SMPROGRAMS\$StartMenuFolder"

	DeleteRegKey /ifempty HKLM "Software\${PRODUCT}"

	Push $INSTDIR
	Call un.RemoveFromPath
SectionEnd


;; AddToPath / RemoveFromPath functions originate from CMake - Cross Platform Makefile Generator
;; Copyright 2000-2022 Kitware, Inc. and Contributors
;; All rights reserved.

!define NT_all_env     'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'

; StrStr
; input, top of stack = string to search for
;        top of stack-1 = string to search in
; output, top of stack (replaces with the portion of the string remaining)
; modifies no other variables.
;
; Usage:
;   Push "this is a long ass string"
;   Push "ass"
;   Call StrStr
;   Pop $R0
;  ($R0 at this point is "ass string")
!macro StrStr un
Function ${un}StrStr
Exch $R1 ; st=haystack,old$R1, $R1=needle
  Exch    ; st=old$R1,haystack
  Exch $R2 ; st=old$R1,old$R2, $R2=haystack
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1=needle
  ; $R2=haystack
  ; $R3=len(needle)
  ; $R4=cnt
  ; $R5=tmp
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 done
    StrCmp $R5 "" done
    IntOp $R4 $R4 + 1
    Goto loop
done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1
FunctionEnd
!macroend
!insertmacro StrStr ""
!insertmacro StrStr "un."

Function Trim
	Exch $R1
	Push $R2
Loop:
	StrCpy $R2 "$R1" 1 -1
	StrCmp "$R2" " " RTrim
	StrCmp "$R2" "$\n" RTrim
	StrCmp "$R2" "$\r" RTrim
	StrCmp "$R2" ";" RTrim
	GoTo Done
RTrim:
	StrCpy $R1 "$R1" -1
	Goto Loop
Done:
	Pop $R2
	Exch $R1
FunctionEnd


; AddToPath - Adds the given dir to the search path.
;        Input - head of the stack
Function AddToPath
  Exch $0
  Push $1
  Push $2
  Push $3
  ReadEnvStr $1 PATH
  ; if the path is too long for a NSIS variable NSIS will return a 0
  ; length string.  If we find that, then warn and skip any path
  ; modification as it will trash the existing path.
  StrLen $2 $1
  IntCmp $2 0 CheckPathLength_ShowPathWarning CheckPathLength_Done CheckPathLength_Done
    CheckPathLength_ShowPathWarning:
    Messagebox MB_OK|MB_ICONEXCLAMATION "Warning! PATH too long installer unable to modify PATH!"
    Goto AddToPath_done
  CheckPathLength_Done:
  Push "$1;"
  Push "$0;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
  Push "$1;"
  Push "$0\;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
  GetFullPathName /SHORT $3 $0
  Push "$1;"
  Push "$3;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
  Push "$1;"
  Push "$3\;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done

      ReadRegStr $1 ${NT_all_env} "PATH"
    StrCmp $1 "" AddToPath_NTdoIt
      Push $1
      Call Trim
      Pop $1
      StrCpy $0 "$1;$0"
    AddToPath_NTdoIt:
        WriteRegExpandStr ${NT_all_env} "PATH" $0
      SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  AddToPath_done:
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd


; RemoveFromPath - Remove a given dir from the path
;     Input: head of the stack
Function un.RemoveFromPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6
  IntFmt $6 "%c" 26 # DOS EOF

      ReadRegStr $1 ${NT_all_env} "PATH"
    StrCpy $5 $1 1 -1 # copy last char
    StrCmp $5 ";" +2 # if last char != ;
      StrCpy $1 "$1;" # append ;
    Push $1
    Push "$0;"
    Call un.StrStr ; Find `$0;` in $1
    Pop $2 ; pos of our dir
    StrCmp $2 "" unRemoveFromPath_done
      ; else, it is in path
      # $0 - path to add
      # $1 - path var
      StrLen $3 "$0;"
      StrLen $4 $2
      StrCpy $5 $1 -$4 # $5 is now the part before the path to remove
      StrCpy $6 $2 "" $3 # $6 is now the part after the path to remove
      StrCpy $3 $5$6
      StrCpy $5 $3 1 -1 # copy last char
      StrCmp $5 ";" 0 +2 # if last char == ;
        StrCpy $3 $3 -1 # remove last char
        WriteRegExpandStr ${NT_all_env} "PATH" $3
      SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  unRemoveFromPath_done:
    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd
