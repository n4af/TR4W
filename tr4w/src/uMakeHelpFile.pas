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

