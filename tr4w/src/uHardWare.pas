{
 Copyright Dmitriy Gulyaev UA4WLI 2015.

 This file is part of TR4W  (SRC)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT. 
If not, ref: 
http://www.gnu.org/licenses/gpl-3.0.txt
 }
unit uHardWare;
interface

uses
  LogRadio,
  uCAT,
  Windows,
  Messages,
  uCommctrl;

var
  PSP                                   : TPropSheetPage;
  ahpsp                                 : array[0..2] of HPropSheetPage; //Колличество страниц (2)
  PSH                                   : TPropSheetHeader;
//  Caption                               : array[0..255] of Char;
procedure RunHardWarePropertySheet;
implementation

procedure InitPropertySheet;
begin
  Randomize;

  // page #1
  PSP.dwSize := SizeOf(PSP);
  PSP.dwFlags := PSP_USEICONID or PSP_USETITLE ;
  PSP.hInstance := hInstance;
  PSP.pfnDlgProc := @CATDlgProc; 
  PSP.pszIcon := MAKEINTRESOURCE(1);
  PSP.pszTemplate := MAKEINTRESOURCE(66);
  PSP.pszTitle := 'Radio 1';
  PSP.lParam := integer(@Radio1);


  ahpsp[0] := CreatePropertySheetPage(PSP);
  // page #2
  PSP.dwFlags := PSP_DEFAULT or PSP_USEICONID or PSP_USETITLE; //Активная кнопка Справка
  PSP.hInstance := hInstance;
  PSP.pfnDlgProc := @CATDlgProc;
  PSP.pszIcon := MAKEINTRESOURCE(1);
  PSP.pszTemplate := MAKEINTRESOURCE(66);
  PSP.pszTitle := 'Radio 2';
  PSP.lParam := integer(@Radio2);

  ahpsp[1] := CreatePropertySheetPage(PSP);
  // create the Property sheet
  ZeroMemory(@PSH, SizeOf(PSH));
  PSH.dwSize := SizeOf(PSH);
  PSH.hInstance := hInstance;
  PSH.hwndParent := 0;
  PSH.phpage := @ahpsp[0];
  PSH.nStartPage := 0; //Стартовая страница
  PSH.nPages := 2; //Колличество страниц
  PSH.dwFlags := PSH_DEFAULT or PSH_NOCONTEXTHELP or PSH_USEICONID or PSH_HASHELP or PSH_PROPTITLE;
  PSH.pszCaption := 'HardWare'; //Заголовок Блоктнота из ресурсов
//  PSH.pszIcon := MAKEINTRESOURCE(1); //Значок в заголовке из ресурсов
  PSH.pfnCallback := nil;
end;

procedure RunHardWarePropertySheet;
begin
  InitPropertySheet;
  PropertySheet(PSH);
end;

end.

