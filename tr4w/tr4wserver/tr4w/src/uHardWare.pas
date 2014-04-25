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

