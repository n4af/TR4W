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
