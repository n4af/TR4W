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
unit uInet;

interface

uses
  SysUtils,
  Classes,
  WinInet,
  EncdDecd;

function SslInet(Const AServer, AUrl, AData, ALogin, APass: AnsiString; isSSL: Boolean = True): AnsiString;

implementation

function SslInet(Const AServer, AUrl, AData, ALogin, APass: AnsiString; isSSL: Boolean = True): AnsiString;
var
  aBuffer     : Array[0..4096] of Char;
  Header      : TStringStream;
  BufStream   : TMemoryStream;
  sMethod     : AnsiString;
  BytesRead   : Cardinal;
  pSession    : HINTERNET;
  pConnection : HINTERNET;
  pRequest    : HINTERNET;
  authEncode  : AnsiString;
begin

  Result := '';

  pSession := InternetOpen(nil, INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);

  if Assigned(pSession) then
    try

     case isSSL of
       True  :  pConnection := InternetConnect(pSession, PChar(AServer), INTERNET_DEFAULT_HTTPS_PORT, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
       False :  pConnection := InternetConnect(pSession, PChar(AServer), INTERNET_DEFAULT_HTTP_PORT, nil, nil, INTERNET_SERVICE_HTTP, 0, 0);
     end;

    if Assigned(pConnection) then
      try

        if (AData = '') then
          sMethod := 'GET'
        else
          sMethod := 'POST';

        case isSSL of
          True  : pRequest := HTTPOpenRequest(pConnection, PChar(sMethod), PChar(AURL), nil, nil, nil, INTERNET_FLAG_SECURE  or INTERNET_FLAG_KEEP_CONNECTION, 0);
          False : pRequest := HTTPOpenRequest(pConnection, PChar(sMethod), PChar(AURL), nil, nil, nil, INTERNET_SERVICE_HTTP, 0);
        end;

        if Assigned(pRequest) then
          try

            authEncode := EncdDecd.EncodeString(ALogin + ':' + APass);

            Header := TStringStream.Create('');

            with Header do
            begin
              WriteString('Host: ' + AServer + sLineBreak);
              WriteString('Authorization: Basic ' + authEncode + sLineBreak);
              WriteString('Connection: close' + sLineBreak + sLineBreak);
            end;

            HttpAddRequestHeaders(pRequest, PChar(Header.DataString), Length(Header.DataString), HTTP_ADDREQ_FLAG_ADD);

            if HTTPSendRequest(pRequest, nil, 0, Pointer(AData), Length(AData)) then
            begin

              BufStream := TMemoryStream.Create;
              try

                 while InternetReadFile(pRequest, @aBuffer, SizeOf(aBuffer), BytesRead) do
                 begin
                   if (BytesRead = 0) then Break;
                   BufStream.Write(aBuffer, BytesRead);
                 end;

                 aBuffer[0] := #0;
                 BufStream.Write(aBuffer, 1);
                 Result := PChar(BufStream.Memory);

              finally
                FreeAndNil(BufStream);
              end;

            end;

          finally
            InternetCloseHandle(pRequest);
            FreeAndNil(Header);
          end;

      finally
        InternetCloseHandle(pConnection);
      end;

    finally
      InternetCloseHandle(pSession);
    end;
    
end;

end.
