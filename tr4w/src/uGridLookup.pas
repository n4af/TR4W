{
 Copyright Thomas M. Schaefer, NY4I (c) 2020.
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

unit uGridLookup;


interface

uses Classes, SysUtils;

Type TGridLookup = class(TObject)
   private
      slGrids: TStringList;
      constructor Create;
      destructor Destroy;
      function GetGridIndex(sGrid: string): integer;
   protected
   public
      procedure AddStateToGrid(sGrid: string; sState: string);
      procedure AddSectionToGrid(sGrid: string; sSection: string);
      function ReturnStatesForGrid(sGrid: string; var slStates: TStringList): boolean;
end;

implementation

constructor TGridLookup.Create;
   begin
   slGrids := TStringList.Create;
   Self.AddStateToGrid('EL87','FL');
   Self.AddStateToGrid('EL88','FL');
   end;

destructor TGridLookup.Destroy;
var
   i: integer;
   begin

   for i := 0 to slGrids.Count do
      begin
      slGrids.Objects[i].Free;
      end;
   slGrids.Free;
   end;


procedure TGridLookup.AddStateToGrid(sGrid: string; sState: string);
   var
      i: integer;
      slStates: TStringList;
   begin
   i := GetGridIndex(sGrid);
   if i < 0 then
      begin   // Create a state and section object
      slStates := TStringList.Create;
      slStates.Add(sState);
      slGrids.AddObject(sGrid, slStates);
      end
   else
      begin
      slStates := TStringList(slGrids.Objects[i]);
      if slStates.IndexOf(sState) < 0 then
         begin
         slStates.Add(sState);
         end;
      end;
   end;

procedure TGridLookup.AddSectionToGrid(sGrid: string; sSection: string);
   begin
   end;

function TGridLookup.ReturnStatesForGrid(sGrid: string; var slStates: TStringList): boolean;
   var
      i: integer;
   begin
   Result := false;
   i := GetGridIndex(sGrid);
   if i < 0 then
      begin   // Create a state and section object
      Exit;
      end
   else
      begin
      //localStates := TStringList(slGrids.Objects[i]);
      slStates.AddStrings(TStringList(slGrids.Objects[i]));
      end;
   end;

function TGridLookup.GetGridIndex(sGrid: string): integer;
   begin
   Result := Self.slGrids.IndexOf(sGrid);
   end;
end.
