unit uMakeHelpFile;

interface

uses
  TF,
  VC,
  Tree, Windows
  ;

var h                                   : Text;

procedure AddEntryToHHC(SectionName, FileName: ShortString; Image: integer);
procedure MakeHHCFile;

implementation

procedure AddEntryToHHC(SectionName, FileName: ShortString; Image: integer);
begin
  WriteLn(h, '<LI><OBJECT type="text/sitemap"><PARAM name="Name" value="' + SectionName + '"><PARAM name="Local" value="' + FileName + '"><PARAM name="ImageNumber" value="' + IntToStr(Image) + '"></OBJECT>');
end;

procedure MakeHHCFile;

begin
{
  OpenFileForWrite(h, 'D:\TR4W_WinAPI\out\Help\tr4whelp\tr4w.hhc');
  WriteLn(h, '<HTML><BODY><OBJECT type="text/site properties"><PARAM name="Window Styles" value="0x800027"></OBJECT><UL>');

  AddEntryToHHC('TR4W', 'index.html', 11);
  AddEntryToHHC('»нсталл€ци€', 'installation.txt', 11);
  AddEntryToHHC('—оздание нового лога', 'newlog.txt', 11);

  WriteLn(h, '</UL></BODY></HTML>');
  Close(h);
}
end;

end.

