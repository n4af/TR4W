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
unit TIMEDIFF;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, ControlS, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    ListBox1: TListBox;
    ListBox2: TListBox;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1                                 : TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  i                                     : integer;
  s                                     : string;
  ts                                    : tstringlist;
  Time                                  : string;
  sql                                   : string;
begin
  ts := tstringlist.Create;
  ListBox1.Items.LoadFromFile('RK4FWX.cbr');
  ListBox2.Items.Add('INSERT INTO LB (DATE,CALL1) VALUES');

  for i := 0 to ListBox1.Items.Count - 1 do
    if Copy(ListBox1.Items[i], 1, 3) = 'QSO' then
    begin
      s := ListBox1.Items[i];
      ts.CommaText := s;
      Time := Copy(ts[4], 1, 2) + ':' + Copy(ts[4], 3, 2) + ':00';
      sql := '(''' + ts[3] + ' ' + Time + ''',''' + ts[8] + ''')';
      if i <> (ListBox1.Items.Count - 1) then sql := sql + ',';
      ListBox2.Items.Add(sql);
    end;
  ListBox2.Items.SaveToFile('sql.txt');
end;

end.

